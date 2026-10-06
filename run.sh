#!/usr/bin/env bash
#
# Benchmark harness for the framework comparison.
#
# Default mode runs every demo in its own Docker container capped at 4 CPU cores and 4 GiB
# of RAM, pins the container to one set of cores and `ab` to a different set (so the load
# generator cannot steal the server's CPU), then writes report.md.
#
# Each demo-*/run.sh implements four subcommands and is the single source of truth for that
# framework's port and benchmark URL:
#   meta   print NAME=, STACK=, PORT=, BENCH_PATH=
#   check  exit 0 if the toolchain is present (native mode only)
#   build  compile / install deps (native mode only)
#   start  exec the server in the foreground on $PORT
# Each demo-*/Dockerfile builds with the REPO ROOT as context and ends in `./run.sh start`.
#
#   ./run.sh                           build + benchmark everything, in Docker
#   ./run.sh --only rust,java          just those
#   ./run.sh --native                  run on the host instead of in containers
#   ./run.sh -n 2000 -c "1 10 100"     fewer requests / levels
#   ./run.sh --cpus 2 --memory 2g      different container caps
#   ./run.sh --no-build                reuse existing images / builds
#   ./run.sh --list                    show what was discovered
#   ./run.sh --report-only             rebuild the report from stored results, measure nothing
#   ./run.sh --loadgen ab              single-URL ab instead of the mixed k6 suite
#   ./run.sh --no-tag                  skip creating the bench/<date>-<n> git tag
#
set -uo pipefail
# Deterministic numeric formatting: under a comma-decimal locale, awk parses "12345.67"
# from /proc/uptime as 12345 and printf renders sizes as "30,5 GiB".
export LC_ALL=C
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

MODE="${MODE:-docker}"
REQUESTS="${REQUESTS:-10000}"
LEVELS="${LEVELS:-1 10 100 1000 10000}"
CPUS="${CPUS:-4}"
MEMORY="${MEMORY:-4g}"
REPORT="${REPORT:-$ROOT/report.adoc}"
LOGDIR="${LOGDIR:-$ROOT/.bench-logs}"
RESULTDIR="${RESULTDIR:-$LOGDIR/results}"
READY_TIMEOUT="${READY_TIMEOUT:-120}"
HOSTPORT_BASE="${HOSTPORT_BASE:-19080}"
LOADGEN="${LOADGEN:-k6}"
K6_IMAGE="${K6_IMAGE:-grafana/k6:2.3.0}"
K6_SCRIPT="${K6_SCRIPT:-$ROOT/bench/mixed.js}"
JOURNAL="${JOURNAL:-WAL}"
DEMO_DB="${DEMO_DB:-$ROOT/demo.sqlite}"
ONLY=""
DO_BUILD=1
LIST_ONLY=0
DO_TAG=1

NCPU="$(nproc)"
SERVER_CPUS="${SERVER_CPUS:-}"
LOAD_CPUS="${LOAD_CPUS:-}"

# Choose $1 distinct PHYSICAL cores for the server, preferring efficiency cores (lowest max
# clock) and taking one hyperthread each, then hand every remaining cpu to the load generator.
# On a hybrid chip "--cpus 4" would otherwise mean 4 hyperthreads on 2 P-cores, which is both
# less throughput than it sounds and far less reproducible (boost and thermal swings).
# Prints "<server-cpuset> <load-cpuset>", or an empty line if detection is not possible.
detect_cpuset() {
    python3 -I - "$1" <<'DETECT'
import sys, pathlib
want = int(sys.argv[1])
base = pathlib.Path('/sys/devices/system/cpu')
cores = {}
for d in sorted(base.glob('cpu[0-9]*'), key=lambda p: int(p.name[3:])):
    cpu = int(d.name[3:])
    sib, core = d / 'topology' / 'thread_siblings_list', d / 'topology' / 'core_id'
    if not sib.exists() or not core.exists():
        continue
    cid = int(core.read_text().strip())
    f = d / 'cpufreq' / 'cpuinfo_max_freq'
    freq = int(f.read_text().strip()) if f.exists() else 0
    e = cores.setdefault(cid, {'threads': [], 'freq': 0})
    e['threads'].append(cpu)
    e['freq'] = max(e['freq'], freq)
allc = sorted(c for e in cores.values() for c in e['threads'])
order = sorted(cores.items(), key=lambda kv: (kv[1]['freq'], kv[0]))
if len(order) < want or not allc:
    print(''); sys.exit()
server = sorted(order[i][1]['threads'][0] for i in range(want))
load = [c for c in allc if c not in set(server)]
def rng(xs):
    out = []
    for x in xs:
        if out and x == out[-1][1] + 1: out[-1][1] = x
        else: out.append([x, x])
    return ','.join(str(a) if a == b else f'{a}-{b}' for a, b in out)
print(rng(server), rng(load) if load else '')
DETECT
}

while [ $# -gt 0 ]; do
    case "$1" in
        --only) ONLY="${2//,/ }"; shift 2 ;;
        --native) MODE=native; shift ;;
        --docker) MODE=docker; shift ;;
        --no-build) DO_BUILD=0; shift ;;
        -n|--requests) REQUESTS="$2"; shift 2 ;;
        -c|--concurrency) LEVELS="$2"; shift 2 ;;
        --cpus) CPUS="$2"; shift 2 ;;
        --memory) MEMORY="$2"; shift 2 ;;
        --server-cpus) SERVER_CPUS="$2"; shift 2 ;;
        --load-cpus) LOAD_CPUS="$2"; shift 2 ;;
        --journal) JOURNAL="$2"; shift 2 ;;
        --loadgen) LOADGEN="$2"; shift 2 ;;
        --no-tag) DO_TAG=0; shift ;;
        --list) LIST_ONLY=1; shift ;;
        --report-only) ONLY="__none__"; DO_BUILD=0; shift ;;
        -h|--help) sed -n '2,28p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# Resolve the cpusets now that --cpus / --server-cpus / --load-cpus have all been seen.
if [ -z "$SERVER_CPUS" ] || [ -z "$LOAD_CPUS" ]; then
    detected="$(detect_cpuset "$CPUS" 2>/dev/null || true)"
    [ -n "$SERVER_CPUS" ] || SERVER_CPUS="$(awk '{print $1}' <<<"$detected")"
    [ -n "$LOAD_CPUS" ]   || LOAD_CPUS="$(awk '{print $2}' <<<"$detected")"
fi
[ -n "$SERVER_CPUS" ] || SERVER_CPUS="0-$((CPUS - 1))"

if [ "$LOADGEN" = ab ]; then
    command -v ab >/dev/null 2>&1 || { echo "ab (apache2-utils) is required" >&2; exit 1; }
elif [ "$LOADGEN" = k6 ]; then
    [ -f "$K6_SCRIPT" ] || { echo "k6 script not found: $K6_SCRIPT" >&2; exit 1; }
    command -v docker >/dev/null 2>&1 || { echo "docker is required to run k6" >&2; exit 1; }
else
    echo "unknown --loadgen: $LOADGEN (expected k6 or ab)" >&2; exit 1
fi

# Random ids for the item endpoint are drawn from 1..MAX_ID.
MAX_ID="${MAX_ID:-$(python3 -I -c "
import sqlite3,sys
print(sqlite3.connect('file:' + sys.argv[1] + '?immutable=1', uri=True).execute('select max(id) from content').fetchone()[0])
" "$DEMO_DB" 2>/dev/null || echo 10000)}"
if [ "$MODE" = docker ]; then
    command -v docker >/dev/null 2>&1 || { echo "docker is required for --docker mode" >&2; exit 1; }
    docker info >/dev/null 2>&1 || { echo "cannot reach the docker daemon" >&2; exit 1; }
fi

if [ "$MODE" = docker ]; then
    LIMITS_DESC="--cpus=$CPUS --cpuset-cpus=$SERVER_CPUS --memory=$MEMORY (swap disabled)"
else
    LIMITS_DESC="native, unconstrained"
fi

# Derived from bench/mixed.js so the report cannot claim a mix the results were not run under.
if [ "$LOADGEN" = k6 ] && [ -f "$K6_SCRIPT" ]; then
    MIX_DESC="$(python3 -I -c "
import re, sys
src = open(sys.argv[1]).read()
parts = []
for weight, body in re.findall(r'\{\s*weight:\s*(\d+)\s*,([^}]*)\}', src):
    kind = re.search(r\"kind:\s*'([a-z]+)'\", body)
    size = re.search(r'size:\s*(\d+)', body)
    label = kind.group(1) if kind else '?'
    if size:
        label += ' size=' + size.group(1)
    parts.append(weight + '% ' + label)
print(' | '.join(parts))
" "$K6_SCRIPT" 2>/dev/null || echo "?")"
else
    MIX_DESC="single URL"
fi

AB=(ab)
if [ -n "$LOAD_CPUS" ] && command -v taskset >/dev/null 2>&1; then
    AB=(taskset -c "$LOAD_CPUS" ab)
fi

mkdir -p "$LOGDIR" "$RESULTDIR"
LOADAVG_START="$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || echo '?')"
GIT_COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo '?')"
GIT_BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
if git -C "$ROOT" diff --quiet 2>/dev/null && git -C "$ROOT" diff --cached --quiet 2>/dev/null; then
    GIT_DIRTY=""
else
    GIT_DIRTY=" (uncommitted changes present)"
fi
ulimit -n 65535 2>/dev/null || true

port_open() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }

# Monotonic milliseconds. Wall-clock date(1) can step backwards under NTP mid-run.
now_ms() { awk '{printf "%d", $1 * 1000}' /proc/uptime; }

# First free TCP port at or after $1.
pick_port() {
    local p
    for p in $(seq "$1" $(( $1 + 300 ))); do
        port_open "$p" || { echo "$p"; return 0; }
    done
    return 1
}

wait_for_port_free() {
    local port="$1" i
    for i in $(seq 1 60); do port_open "$port" || return 0; sleep 0.25; done
    return 1
}

# Count the rows a framework returned, whatever it calls the list key.
count_rows() {
    python3 -I -c '
import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("?"); sys.exit()
if isinstance(d, list):
    print(len(d)); sys.exit()
if isinstance(d, dict):
    # "content" is the Spring Data Slice key. Named keys are checked before any generic
    # list, because a Slice payload also carries a "sort" array that would match blindly.
    for k in ("contents","content","data","results","items"):
        if isinstance(d.get(k), list):
            print(len(d[k])); sys.exit()
    for v in d.values():
        if isinstance(v, list):
            print(len(v)); sys.exit()
print("?")
' 2>/dev/null || echo "?"
}

# ---- discover ----------------------------------------------------------------
declare -a NAMES STACKS PORTS PATHS DIRS LISTPATHS ITEMPATHS CATPATHS
for sh in "$ROOT"/demo-*/run.sh; do
    [ -f "$sh" ] || continue
    dir="$(dirname "$sh")"
    env_pfx=()
    # In docker mode the PHP demo is served by nginx+php-fpm, which changes its STACK label.
    [ "$MODE" = docker ] && [ "$(basename "$dir")" = demo-php ] && env_pfx=(env PHP_SERVER=fpm)
    meta="$("${env_pfx[@]}" bash "$sh" meta 2>/dev/null)" || continue
    name="$(sed -n 's/^NAME=//p'        <<<"$meta")"
    stack="$(sed -n 's/^STACK=//p'      <<<"$meta")"
    port="$(sed -n 's/^PORT=//p'        <<<"$meta")"
    bpath="$(sed -n 's/^BENCH_PATH=//p' <<<"$meta")"
    lpath="$(sed -n 's/^LIST_PATH=//p' <<<"$meta")"
    ipath="$(sed -n 's/^ITEM_PATH=//p' <<<"$meta")"
    cpath="$(sed -n 's/^CATEGORIES_PATH=//p' <<<"$meta")"
    [ -n "$name" ] || continue
    NAMES+=("$name"); STACKS+=("$stack"); PORTS+=("$port"); PATHS+=("$bpath"); DIRS+=("$dir")
    LISTPATHS+=("$lpath"); ITEMPATHS+=("$ipath"); CATPATHS+=("$cpath")
done

[ "${#NAMES[@]}" -gt 0 ] || { echo "no demos matched" >&2; exit 1; }

if [ "$LIST_ONLY" -eq 1 ]; then
    printf '%-10s %-34s %-6s %s\n' NAME STACK PORT PATH
    for i in "${!NAMES[@]}"; do
        printf '%-10s %-34s %-6s %s\n' "${NAMES[$i]}" "${STACKS[$i]}" "${PORTS[$i]}" "${PATHS[$i]}"
    done
    exit 0
fi

declare -A RPS SKIPPED ROWS BYTES NOTE IMGSIZE BOOTMS BUILDS PEAKMEM P50 P95 P99

if [ "$MODE" = docker ]; then
    echo "mode=docker  cpus=$CPUS (cpuset $SERVER_CPUS)  memory=$MEMORY  ab on cpus=${LOAD_CPUS:-all}"
else
    echo "mode=native  each framework gets a fresh copy of $(basename "$DEMO_DB") (journal_mode=$JOURNAL)"
fi
echo "requests=-n $REQUESTS  levels=-c $LEVELS"
echo

cleanup_docker() { docker rm -f "bfc-$1" >/dev/null 2>&1 || true; }

# Native mode: like a fresh container, every framework starts from its own copy of the dataset,
# so benchmark writes never reach the repo's demo.sqlite or the next framework.
fresh_db() {
    rm -f "$1" "$1-wal" "$1-shm"
    cp "$DEMO_DB" "$1"
    python3 -I -c "
import sqlite3,sys
sqlite3.connect(sys.argv[1]).execute('pragma journal_mode=' + sys.argv[2]).close()
" "$1" "$JOURNAL"
}
drop_db() { rm -f "$1" "$1-wal" "$1-shm"; }

for i in "${!NAMES[@]}"; do
    name="${NAMES[$i]}"; dir="${DIRS[$i]}"; port="${PORTS[$i]}"; bpath="${PATHS[$i]}"
    # In docker mode the app keeps its native port inside the container and we publish it on a
    # free host port, so a service already bound to e.g. 8080 on the host cannot block the run.
    if [ "$MODE" = docker ] && port_open "$port"; then
        hostport="$(pick_port "$((HOSTPORT_BASE + i))")" || { echo "no free host port" >&2; exit 1; }
    else
        hostport="$port"
    fi
    url="http://127.0.0.1:${hostport}${bpath}"
    log="$LOGDIR/$name"
    pgid=""
    if [ -n "$ONLY" ] && ! grep -qw "$name" <<<"$ONLY"; then continue; fi
    echo "=== $name (${STACKS[$i]}) ==="

    # ---- build -------------------------------------------------------------
    if [ "$MODE" = docker ]; then
        if [ ! -f "$dir/Dockerfile" ]; then
            SKIPPED[$name]="no Dockerfile in $(basename "$dir")"
            echo "    SKIP - ${SKIPPED[$name]}"; echo; continue
        fi
        if [ "$DO_BUILD" -eq 1 ]; then
            echo "--- docker build"
            t0=$(date +%s)
            if ! docker build -f "$dir/Dockerfile" -t "bfc-$name:bench" "$ROOT" >"$log.build.log" 2>&1; then
                SKIPPED[$name]="docker build failed (see $log.build.log)"
                echo "    SKIP - build failed; last lines:"
                tail -8 "$log.build.log" | sed 's/^/      /'
                echo; continue
            fi
            BUILDS[$name]="$(( $(date +%s) - t0 ))"
            echo "    built in ${BUILDS[$name]}s"
        fi
        docker image inspect "bfc-$name:bench" >/dev/null 2>&1 || {
            SKIPPED[$name]="image bfc-$name:bench not built (drop --no-build)"
            echo "    SKIP - ${SKIPPED[$name]}"; echo; continue
        }
        IMGSIZE[$name]="$(docker image inspect -f '{{.Size}}' "bfc-$name:bench" 2>/dev/null)"
    else
        if ! bash "$dir/run.sh" check >"$log.check.log" 2>&1; then
            SKIPPED[$name]="toolchain missing: $(tr -d '\n' <"$log.check.log" | cut -c1-70)"
            echo "    SKIP - ${SKIPPED[$name]}"; echo; continue
        fi
        if [ "$DO_BUILD" -eq 1 ]; then
            echo "--- build"
            t0=$(date +%s)
            if ! bash "$dir/run.sh" build >"$log.build.log" 2>&1; then
                SKIPPED[$name]="build failed (see $log.build.log)"
                echo "    SKIP - build failed; last lines:"
                tail -8 "$log.build.log" | sed 's/^/      /'
                echo; continue
            fi
            BUILDS[$name]="$(( $(date +%s) - t0 ))"
        fi
    fi

    # ---- start -------------------------------------------------------------
    cleanup_docker "$name"
    if port_open "$hostport"; then
        SKIPPED[$name]="host port $hostport already in use"
        echo "    SKIP - ${SKIPPED[$name]}"; echo; continue
    fi

    if [ "$MODE" = docker ] && [ "$hostport" != "$port" ]; then
        echo "--- start (port $hostport, default $port was busy)"
    else
        echo "--- start (port $hostport)"
    fi
    t0=$(now_ms)
    if [ "$MODE" = docker ]; then
        docker run -d --name "bfc-$name" \
            --cpus="$CPUS" --cpuset-cpus="$SERVER_CPUS" \
            --memory="$MEMORY" --memory-swap="$MEMORY" \
            --network host -e PORT="$hostport" \
            "bfc-$name:bench" >"$log.cid" 2>"$log.server.log" || {
                SKIPPED[$name]="docker run failed: $(tr -d '\n' <"$log.server.log" | cut -c1-90)"
                echo "    SKIP - ${SKIPPED[$name]}"; echo; continue
            }
    else
        fresh_db "$log.sqlite"
        DEMO_DB="$log.sqlite" setsid bash "$dir/run.sh" start >"$log.server.log" 2>&1 &
        pgid=$!
    fi

    ready=0
    for _ in $(seq 1 "$READY_TIMEOUT"); do
        if curl -sf -o /dev/null --max-time 5 "$url"; then ready=1; break; fi
        if [ "$MODE" = docker ]; then
            [ "$(docker inspect -f '{{.State.Running}}' "bfc-$name" 2>/dev/null)" = true ] || break
        else
            kill -0 "$pgid" 2>/dev/null || break
        fi
        sleep 1
    done

    if [ "$ready" -ne 1 ]; then
        SKIPPED[$name]="never became ready on $url"
        echo "    SKIP - not ready; last lines:"
        if [ "$MODE" = docker ]; then
            docker logs --tail 8 "bfc-$name" 2>&1 | sed 's/^/      /'
            docker logs "bfc-$name" >"$log.server.log" 2>&1 || true
            cleanup_docker "$name"
        else
            tail -8 "$log.server.log" | sed 's/^/      /'
            kill -TERM -"$pgid" 2>/dev/null; sleep 1; kill -KILL -"$pgid" 2>/dev/null
            drop_db "$log.sqlite"
        fi
        wait_for_port_free "$hostport"
        echo; continue
    fi
    BOOTMS[$name]="$(( $(now_ms) - t0 ))"

    body="$(curl -sf --max-time 10 "$url")"
    ROWS[$name]="$(count_rows <<<"$body")"
    BYTES[$name]="${#body}"
    echo "    ready in ${BOOTMS[$name]}ms: ${ROWS[$name]} rows, ${BYTES[$name]} bytes"

    # ---- measure -----------------------------------------------------------
    for c in $LEVELS; do
        out="$log.c$c.log"
        if [ "$LOADGEN" = k6 ]; then
            if docker run --rm --network host \
                    ${LOAD_CPUS:+--cpuset-cpus="$LOAD_CPUS"} \
                    -v "$K6_SCRIPT":/mix.js:ro \
                    -e BASE="http://127.0.0.1:${hostport}" \
                    -e LIST_PATH="${LISTPATHS[$i]}" \
                    -e ITEM_PATH="${ITEMPATHS[$i]}" \
                    -e CATEGORIES_PATH="${CATPATHS[$i]}" \
                    -e WRITE_PATH="${ITEMPATHS[$i]}" \
                    -e MAX_ID="$MAX_ID" \
                    "$K6_IMAGE" run --quiet --vus "$c" --iterations "$REQUESTS" /mix.js \
                    >"$out" 2>&1; then
                read -r r f p50 p95 p99 pmax nfail <<<"$(sed -n 's/^K6SUMMARY //p' "$out" | head -1 | python3 -I -c "
import json,sys
raw = sys.stdin.read().strip()
if not raw:
    print('- - - - - - 0'); sys.exit()
d = json.loads(raw)
fmt = lambda v: ('%.2f' % v) if isinstance(v, (int, float)) else '-'
print(fmt(d.get('rps')), fmt(d.get('failed_rate')), fmt(d.get('p50')), fmt(d.get('p95')),
      fmt(d.get('p99')), fmt(d.get('max')), int(d.get('failed_count') or 0))
" 2>/dev/null)"
                if [ "${r:--}" != "-" ] && [ "$(awk -v f="${f:-1}" 'BEGIN{print (f+0 < 0.01) ? 1 : 0}')" = 1 ]; then
                    # A few stalled requests can dominate wall-clock and wreck req/s while still
                    # passing the failure gate, so mark the level instead of reporting it clean.
                    suspect=""
                    if [ "${nfail:-0}" -gt 0 ]; then
                        suspect="*"
                        NOTE[$name]="${NOTE[$name]:-}c$c:${nfail} req errors (max ${pmax}ms); "
                    fi
                    RPS[$name,$c]="${r}${suspect}"; P50[$name,$c]="$p50"
                    P95[$name,$c]="$p95"; P99[$name,$c]="$p99"
                    printf '    c=%-6s %10s req/s%-1s  p50=%-8s p95=%-8s p99=%-8s max=%s\n' \
                        "$c" "$r" "$suspect" "$p50" "$p95" "$p99" "$pmax"
                else
                    RPS[$name,$c]="Failed"
                    NOTE[$name]="${NOTE[$name]:-}c$c:fail rate ${f:-?}; "
                    printf '    c=%-6s %10s  (fail rate %s)\n' "$c" "Failed" "${f:-?}"
                fi
            else
                RPS[$name,$c]="Failed"
                NOTE[$name]="${NOTE[$name]:-}c$c:k6 aborted; "
                printf '    c=%-6s %10s  (k6 aborted)\n' "$c" "Failed"
            fi
        elif "${AB[@]}" -n "$REQUESTS" -c "$c" -s 60 -r "$url" >"$out" 2>&1; then
            r="$(sed -n 's/^Requests per second: *\([0-9.]*\).*/\1/p' "$out" | head -1)"
            nn="$(sed -n 's/^Non-2xx responses: *\([0-9]*\).*/\1/p' "$out" | head -1)"
            fr="$(sed -n 's/^Failed requests: *\([0-9]*\).*/\1/p' "$out" | head -1)"
            if [ -n "$r" ] && [ "${nn:-0}" = "0" ]; then
                RPS[$name,$c]="$r"
                extra=""
                [ "${fr:-0}" != "0" ] && { extra="  (${fr} failed)"; NOTE[$name]="${NOTE[$name]:-}c$c:${fr} failed; "; }
                printf '    c=%-6s %10s req/s%s\n' "$c" "$r" "$extra"
            else
                RPS[$name,$c]="Failed"
                [ "${nn:-0}" != "0" ] && NOTE[$name]="${NOTE[$name]:-}c$c:${nn} non-2xx; "
                printf '    c=%-6s %10s  (%s non-2xx)\n' "$c" "Failed" "${nn:-?}"
            fi
        else
            RPS[$name,$c]="Failed"
            NOTE[$name]="${NOTE[$name]:-}c$c:ab aborted; "
            printf '    c=%-6s %10s  (ab aborted)\n' "$c" "Failed"
        fi
    done

    # ---- persist -----------------------------------------------------------
    # One file per framework so a partial run (--only) updates just its own rows
    # instead of replacing the whole report.
    {
        echo "STACK=${STACKS[$i]}"
        echo "BPATH=${PATHS[$i]}"
        echo "ROWS=${ROWS[$name]:-}"
        echo "BYTES=${BYTES[$name]:-}"
        echo "BOOTMS=${BOOTMS[$name]:-}"
        echo "IMGSIZE=${IMGSIZE[$name]:-}"
        echo "BUILD=${BUILDS[$name]:-}"
        echo "NOTE=${NOTE[$name]:-}"
        echo "WHEN=$(date -Is)"
        echo "MODE=$MODE"
        echo "LIMITS=$LIMITS_DESC"
        echo "MIX=$MIX_DESC"
        echo "REQUESTS=$REQUESTS"
        echo "LEVELS=$LEVELS"
        echo "LOADGEN=$LOADGEN"
        for c in $LEVELS; do
            echo "RPS_$c=${RPS[$name,$c]:-}"
            echo "P50_$c=${P50[$name,$c]:-}"
            echo "P95_$c=${P95[$name,$c]:-}"
            echo "P99_$c=${P99[$name,$c]:-}"
        done
    } >"$RESULTDIR/$name.env"

    # ---- teardown ----------------------------------------------------------
    if [ "$MODE" = docker ]; then
        PEAKMEM[$name]="$(docker exec "bfc-$name" cat /sys/fs/cgroup/memory.peak 2>/dev/null | tr -d '\r')"
        echo "PEAKMEM=${PEAKMEM[$name]:-}" >>"$RESULTDIR/$name.env"
        docker logs "bfc-$name" >"$log.server.log" 2>&1 || true
        cleanup_docker "$name"
    else
        kill -TERM -"$pgid" 2>/dev/null; sleep 1; kill -KILL -"$pgid" 2>/dev/null
        drop_db "$log.sqlite"
    fi
    wait_for_port_free "$hostport" || echo "    warn: host port $hostport still busy"
    echo
done

# ---- environment -------------------------------------------------------------
rd() { cat "$1" 2>/dev/null || echo "n/a"; }

# "2 P-cores (SMT, 5000 MHz) + 8 E-cores (3700 MHz)" style summary, derived from sysfs.
cpu_topology() {
    python3 -I - <<'TOPO'
import pathlib
from collections import defaultdict
base = pathlib.Path('/sys/devices/system/cpu')
cores = {}
for d in sorted(base.glob('cpu[0-9]*'), key=lambda p: int(p.name[3:])):
    core = d / 'topology' / 'core_id'
    if not core.exists():
        continue
    cid = int(core.read_text().strip())
    f = d / 'cpufreq' / 'cpuinfo_max_freq'
    freq = int(f.read_text().strip()) // 1000 if f.exists() else 0
    e = cores.setdefault(cid, {'threads': 0, 'freq': freq})
    e['threads'] += 1
    e['freq'] = max(e['freq'], freq)
if not cores:
    print('n/a'); raise SystemExit
groups = defaultdict(lambda: [0, 0])
for info in cores.values():
    g = groups[(info['freq'], info['threads'])]
    g[0] += 1
    g[1] = info['threads']
logical = sum(i['threads'] for i in cores.values())
parts = []
for (freq, threads), (count, _) in sorted(groups.items(), reverse=True):
    smt = ', SMT' if threads > 1 else ''
    parts.append(f"{count} core{'s' if count != 1 else ''} @ {freq} MHz{smt}")
print(f"{logical} logical / {len(cores)} physical: " + ' + '.join(parts))
TOPO
}

emit_environment() {
    local droot dsrc dfs dopts dev rot dbsize
    droot="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo n/a)"
    read -r dsrc dfs dopts <<<"$(findmnt -no SOURCE,FSTYPE,OPTIONS --target "$droot" 2>/dev/null || echo 'n/a n/a n/a')"
    dev="$(sed 's/\[.*//' <<<"$dsrc")"
    rot="$(lsblk -dno ROTA "$dev" 2>/dev/null | tr -d ' ')"
    dbsize="$(stat -c %s "$DEMO_DB" 2>/dev/null | awk '{printf "%.0f KB", $1/1024}')"

    echo '== Environment'
    echo
    echo '=== CPU'
    echo
    echo '[source]'
    echo '----'
    echo "model        $(sed -n 's/^model name[ \t]*: //p' /proc/cpuinfo | head -1)"
    echo "topology     $(cpu_topology)"
    echo "server cpus  $SERVER_CPUS  ($CPUS physical cores, one thread each)"
    echo "load cpus    ${LOAD_CPUS:-all}"
    echo "governor     $(rd /sys/devices/system/cpu/cpufreq/policy0/scaling_governor) ($(rd /sys/devices/system/cpu/cpufreq/policy0/scaling_driver), epp=$(rd /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference))"
    echo "turbo        $([ "$(rd /sys/devices/system/cpu/intel_pstate/no_turbo)" = 0 ] && echo enabled || echo "disabled/unknown")"
    echo '----'
    echo
    if [ "$(rd /sys/devices/system/cpu/cpufreq/policy0/scaling_governor)" != performance ]; then
        echo '[CAUTION]'
        echo '===='
        echo "The CPU governor is not \`performance\`, so clock speed varies with load and package"
        echo 'temperature during the run. On a laptop part this is the largest single source of'
        echo 'run-to-run variance. For a publishable number, pin it first:'
        echo
        echo ' sudo cpupower frequency-set -g performance'
        echo '===='
        echo
    fi
    echo '=== Memory'
    echo
    echo '[source]'
    echo '----'
    awk '/MemTotal/ {printf "total        %.1f GiB\n", $2/1048576} /MemAvailable/ {printf "available    %.1f GiB at run start\n", $2/1048576} /SwapTotal/ {printf "host swap    %.1f GiB\n", $2/1048576}' /proc/meminfo
    echo "container    --memory=$MEMORY, swap disabled (--memory-swap equals --memory)"
    echo "swappiness   $(rd /proc/sys/vm/swappiness)"
    echo "THP          $(sed -n 's/.*\[\(.*\)\].*/\1/p' /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || echo n/a)"
    echo '----'
    echo
    echo '=== Storage'
    echo
    echo '[source]'
    echo '----'
    echo "database     $(basename "$DEMO_DB") ${dbsize:-?}, copied into each image"
    echo "docker root  $droot on $dsrc ($dfs, $dopts)"
    echo "device       $(basename "$dev"), $([ "$rot" = 0 ] && echo non-rotational || echo rotational), scheduler=$(sed -n 's/.*\[\(.*\)\].*/\1/p' "/sys/block/$(lsblk -dno PKNAME "$dev" 2>/dev/null || basename "$dev")/queue/scheduler" 2>/dev/null || echo n/a)"
    echo "free         $(df -h --output=avail,size,pcent "$droot" 2>/dev/null | tail -1 | awk '{print $1" free of "$2" ("$3" used)"}')"
    echo '----'
    echo
    echo 'NOTE: the workload is read-only against a database small enough to sit entirely in the page'
    echo 'cache, so disk characteristics have almost no influence on these numbers. They are recorded'
    echo 'for completeness, and they would matter immediately if write requests were added.'
    echo
    echo '=== Kernel and socket limits'
    echo
    echo '[source]'
    echo '----'
    echo "kernel       $(uname -sr)"
    echo "open files   ulimit -n = $(ulimit -Sn)"
    echo "ephemeral    $(sysctl -n net.ipv4.ip_local_port_range 2>/dev/null | tr '\t' '-') ($(sysctl -n net.ipv4.ip_local_port_range 2>/dev/null | awk '{print $2-$1+1}') ports)"
    echo "somaxconn    $(sysctl -n net.core.somaxconn 2>/dev/null)"
    echo "syn backlog  $(sysctl -n net.ipv4.tcp_max_syn_backlog 2>/dev/null)"
    echo "fin_timeout  $(sysctl -n net.ipv4.tcp_fin_timeout 2>/dev/null) s"
    echo "tw_reuse     $(sysctl -n net.ipv4.tcp_tw_reuse 2>/dev/null)"
    echo '----'
    echo
    echo 'NOTE: the ephemeral port range above caps how many sockets the load generator can hold'
    echo "open at once, and closed sockets linger in TIME_WAIT for fin_timeout seconds. The highest"
    echo 'concurrency level can therefore run into a client-side kernel limit rather than a server'
    echo 'limit, which is one reason a `Failed` there should not be read as a framework verdict. k6'
    echo 'reuses connections by default, so it is far less exposed to this than non-keepalive `ab`.'
    echo
    echo '=== Container runtime'
    echo
    echo '[source]'
    echo '----'
    docker info --format 'docker       {{.ServerVersion}}, {{.Driver}}, cgroup v{{.CgroupVersion}} ({{.CgroupDriver}}), {{.DefaultRuntime}}' 2>/dev/null || echo "docker       n/a"
    echo "security     $(docker info --format '{{range .SecurityOptions}}{{.}} {{end}}' 2>/dev/null | sed 's/name=//g')"
    echo "network      --network host"
    echo '----'
    echo
    echo '=== Measurement hygiene'
    echo
    echo '[source]'
    echo '----'
    echo "commit       $GIT_COMMIT on $GIT_BRANCH$GIT_DIRTY"
    echo "load avg     $LOADAVG_START at start -> $(cut -d' ' -f1-3 /proc/loadavg) at end"
    echo "repetitions  1 per level (no median of repeats)"
    echo "isolation    one server at a time, container removed before the next starts"
    echo '----'
    echo
}

# ---- report ------------------------------------------------------------------
# Rendered as AsciiDoc so README.adoc can include:: it. Rows are read back from
# $RESULTDIR, so `--only x` refreshes x and leaves every other row intact.
human() { [ -n "${1:-}" ] && awk -v b="$1" 'BEGIN{printf "%.0f MiB", b/1048576}' || echo "-"; }
getf() { sed -n "s/^$2=//p" "$RESULTDIR/$1.env" 2>/dev/null | head -1; }

colspec="<28"; for c in $LEVELS; do colspec="$colspec,>10"; done
NLEVELS=0; for c in $LEVELS; do NLEVELS=$((NLEVELS + 1)); done

# Two-row header: "Concurrent connections" spanning the level columns, then the levels.
level_header() {
    echo "[cols=\"$colspec\"]"
    echo '|==='
    echo "| ${NLEVELS}+^h| Concurrent connections"
    printf 'h| %s' "$1"
    for c in $LEVELS; do printf ' ^h| %s' "$c"; done
    echo
    echo
}
stale=0

{
    echo "// Generated by run.sh - do not edit by hand."
    echo "Generated $(date -Is)."
    echo
    echo '== Setup'
    echo
    echo '[source]'
    echo '----'
    echo "mode        $MODE"
    if [ "$MODE" = docker ]; then
        echo "limits      $LIMITS_DESC"
            echo "load gen    ab pinned to cpus ${LOAD_CPUS:-all}"
        echo "database    demo.sqlite copied into each image (no shared file between runs)"
        echo "            journal_mode=$(python3 -I -c "
import sqlite3,sys
print(sqlite3.connect('file:' + sys.argv[1] + '?immutable=1', uri=True).execute('pragma journal_mode').fetchone()[0])
" "$DEMO_DB" 2>/dev/null || echo '?') - identical for every framework"
    else
        echo "database    fresh copy of $DEMO_DB per framework (journal_mode=$JOURNAL)"
    fi
    if [ "$LOADGEN" = k6 ]; then
        echo "load        $K6_IMAGE, mixed read suite (bench/mixed.js)"
        echo "mix         $MIX_DESC"
        echo "            item/write ids drawn at random from 1..$MAX_ID"
    else
        echo "load        ab $(ab -V 2>&1 | sed -n 's/.*Version \([0-9.]*\).*/\1/p' | head -1), single URL"
    fi
    echo "requests    -n $REQUESTS per level"
    echo "levels      -c $LEVELS"
    echo '----'
    echo
    emit_environment
    echo '== Requests per second'
    echo
    level_header 'Platform'
    for i in "${!NAMES[@]}"; do
        name="${NAMES[$i]}"
        [ -f "$RESULTDIR/$name.env" ] || continue
        printf '| %s' "$(getf "$name" STACK)"
        for c in $LEVELS; do printf ' | %s' "$(getf "$name" "RPS_$c" || true)"; done | sed 's/| $/| -/'
        echo
    done
    echo '|==='
    echo

    if [ "$(getf "${NAMES[0]}" LOADGEN)" = k6 ] || [ "$LOADGEN" = k6 ]; then
        echo '== Latency p95 (ms, lower is better)'
        echo
        level_header 'Platform'
        for i in "${!NAMES[@]}"; do
            name="${NAMES[$i]}"
            [ -f "$RESULTDIR/$name.env" ] || continue
            printf '| %s' "$(getf "$name" STACK)"
            for c in $LEVELS; do
                v="$(getf "$name" "P95_$c")"
                printf ' | %s' "${v:--}"
            done
            echo
        done
        echo '|==='
        echo
    fi

    echo 'A `*` marks a level where some requests errored or timed out. Those stalls inflate the'
    echo 'elapsed time the throughput is divided by, so a starred number understates the server and'
    echo 'should not be compared directly. See Partial failures below for the counts.'
    echo
    echo '== Per-framework detail'
    echo
    echo '[cols="<28,<26,>6,>7,>9,>9,>8,>7,<12",options="header"]'
    echo '|==='
    echo '| Platform | Endpoint | Rows | Bytes | First 200 | Peak RSS | Image | Build | Measured'
    echo
    for i in "${!NAMES[@]}"; do
        name="${NAMES[$i]}"
        [ -f "$RESULTDIR/$name.env" ] || continue
        when="$(getf "$name" WHEN)"
        [ "$(getf "$name" LIMITS)" = "$LIMITS_DESC" ] || stale=1
        [ "$(getf "$name" LOADGEN)" = "$LOADGEN" ] || stale=1
        [ "$(getf "$name" MIX)" = "$MIX_DESC" ] || stale=1
        printf '| %s | `%s` | %s | %s | %s | %s | %s | %s | %s\n' \
            "$(getf "$name" STACK)" "$(getf "$name" BPATH)" \
            "$(getf "$name" ROWS)" "$(getf "$name" BYTES)" \
            "$(v=$(getf "$name" BOOTMS); [ -n "$v" ] && echo "$v ms" || echo '-')" \
            "$(human "$(getf "$name" PEAKMEM)")" \
            "$(human "$(getf "$name" IMGSIZE)")" \
            "$(v=$(getf "$name" BUILD); [ -n "$v" ] && echo "${v}s" || echo '-')" \
            "${when%%T*}"
    done
    echo '|==='
    echo

    missing=0
    for i in "${!NAMES[@]}"; do
        [ -f "$RESULTDIR/${NAMES[$i]}.env" ] || missing=1
    done
    if [ "$missing" -eq 1 ]; then
        echo '== Not measured'
        echo
        for i in "${!NAMES[@]}"; do
            name="${NAMES[$i]}"
            [ -f "$RESULTDIR/$name.env" ] && continue
            echo "* *${STACKS[$i]}* - ${SKIPPED[$name]:-not run yet}"
        done
        echo
    fi

    notes=0
    for i in "${!NAMES[@]}"; do
        [ -n "$(getf "${NAMES[$i]}" NOTE)" ] && notes=1
    done
    if [ "$notes" -eq 1 ]; then
        echo '== Partial failures'
        echo
        for i in "${!NAMES[@]}"; do
            name="${NAMES[$i]}"
            n="$(getf "$name" NOTE)"
            [ -n "$n" ] && echo "* *$(getf "$name" STACK)* - ${n%%; }"
        done
        echo
    fi

    if [ "$stale" -eq 1 ]; then
        echo '[WARNING]'
        echo '===='
        echo 'Some rows were measured under different limits or a different load generator than the'
        echo 'run that wrote this report. Check the Measured column and re-run `./run.sh` for a'
        echo 'single consistent set.'
        echo '===='
        echo
    fi

    echo '== Reading these numbers'
    echo
    if [ "$LOADGEN" = k6 ]; then
        echo "* Each framework gets the *same weighted mix* of three endpoints and three page sizes,"
        echo "  so response sizes vary from a few hundred bytes to ~20 KB within a single run. The"
        echo "  per-framework Bytes column below is the size=20 list response, used as a sanity check"
        echo "  that every framework returns the same 20 rows."
        echo "* A level counts as Failed when more than 1% of requests are non-2xx."
    else
        echo "* Every framework is asked for *20 rows* of the same \`content -> category -> parent\`"
        echo "  query, so the Rows column should read 20 everywhere. If it does not, that row is not"
        echo "  comparable."
    fi
    echo "* Every nested category carries its full parent chain (3 levels). Query _count_ is an ORM"
    echo "  property, not a language property: Hibernate (join fetch), EF Core (ThenInclude) and"
    echo "  Django (select_related) load a page in one joined statement, while GORM, Prisma, Eloquent"
    echo "  and SeaORM issue one batched IN query per level, up to 4 statements. That shows up here"
    echo "  as a framework difference."
    echo "* Only one server runs at a time, and each container is removed before the next starts."
    if [ "$LOADGEN" = k6 ]; then
        echo "* k6 is multi-threaded and runs in its own container pinned to the cores the server is"
        echo "  not using, so it is far less likely to be the bottleneck than \`ab\` was."
    else
        echo "* \`ab\` is a single-threaded, non-keepalive load generator. At c=1000+ it is often the"
        echo "  bottleneck rather than the server, which is why the high-concurrency columns compress."
    fi
    echo "* Peak RSS is the container's cgroup \`memory.peak\`, so it includes the runtime, not just"
    echo "  the heap."
    echo "* Raw ab output per level is under \`$(basename "$LOGDIR")/\`."
} >"$REPORT"

# Inline the report into README.adoc between its markers. GitHub does not expand AsciiDoc
# include:: directives, so embedding the text is the only way the results actually show up
# there. Headings are shifted one level so they nest under the enclosing README section.
README_ADOC="${README_ADOC:-$ROOT/README.adoc}"
if [ -f "$README_ADOC" ]; then
    python3 -I - "$README_ADOC" "$REPORT" <<'INJECT'
import pathlib, re, sys
readme, report = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
begin, end = "// BEGIN GENERATED REPORT", "// END GENERATED REPORT"
text = readme.read_text()
if begin not in text or end not in text:
    sys.exit(0)
body = "\n".join(
    re.sub(r"^(=+) ", r"=\1 ", line) if re.match(r"^=+ ", line) else line
    for line in report.read_text().splitlines()
    if not line.startswith("// Generated by run.sh")
).strip("\n")
head, _, rest = text.partition(begin)
_, _, tail = rest.partition(end)
readme.write_text(f"{head}{begin}\n{body}\n{end}{tail}")
print(f"report embedded into {readme}")
INJECT
fi

# Tag the run so every published result set is reachable from git history. A dirty tree is
# refused rather than tagged, because the tag would not reproduce the numbers.
if [ "$DO_TAG" -eq 1 ] && [ "$ONLY" != "__none__" ] && git -C "$ROOT" rev-parse HEAD >/dev/null 2>&1; then
    if [ -n "$GIT_DIRTY" ]; then
        echo "not tagging: working tree is dirty - commit first, then ./run.sh --report-only"
    else
        day="$(date +%Y-%m-%d)"
        n=1
        while git -C "$ROOT" rev-parse -q --verify "refs/tags/bench/$day-$n" >/dev/null 2>&1; do
            n=$((n + 1))
        done
        tag="bench/$day-$n"
        if git -C "$ROOT" tag -a "$tag" -m "Benchmark run $n ($day)

load generator: $LOADGEN
limits: $LIMITS_DESC
requests: -n $REQUESTS per level
levels: -c $LEVELS
commit: $GIT_COMMIT on $GIT_BRANCH" 2>/dev/null; then
            echo "tagged $tag"
        fi
    fi
fi

echo "report written to $REPORT"
