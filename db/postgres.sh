#!/usr/bin/env bash
# The one PostgreSQL server every demo talks to, run as a Docker container, locally on the host
# network or on another machine (PG_REMOTE).
#
#   db/postgres.sh start          start bfc-postgres if needed; (re)load demo_template when
#                                 db/generate.sql changed since it was loaded
#   db/postgres.sh reset NAME     drop database NAME and clone it fresh from demo_template
#   db/postgres.sh psql [ARGS]    psql inside the container (stdin works: -f - or a heredoc)
#   db/postgres.sh host           the address apps connect to (PGHOST)
#   db/postgres.sh cpu            CPU microseconds the container has used so far (cgroup v2)
#   db/postgres.sh stop           remove the container (and its data)
#
# Connection settings shared by run.sh, test.sh and every demo-*/run.sh:
#   host $(db/postgres.sh host), port $PG_PORT (5432), user bench, password bench, superuser.
#
# Local (default): host network, listens on 127.0.0.1 only; PG_CPUS pins it to a cpuset so it
# never shares cores with the app or the load generator.
#
# Remote: PG_REMOTE=user@host runs the container there over ssh ($PG_SSH, default ssh; inside an
# OrbStack VM use PG_SSH="mac ssh" to borrow the Mac's keys). PG_ADDR is the remote's address
# on the link the apps use; the port is published on that address only. The remote machine is
# dedicated to the database, so it is not pinned.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PG_IMAGE="${PG_IMAGE:-postgres:18}"
PG_CONTAINER="${PG_CONTAINER:-bfc-postgres}"
PG_PORT="${PG_PORT:-5432}"
PG_CPUS="${PG_CPUS:-}"
PG_MEMORY="${PG_MEMORY:-4g}"
PG_REMOTE="${PG_REMOTE:-}"
PG_SSH="${PG_SSH:-ssh}"
PG_REMOTE_DOCKER="${PG_REMOTE_DOCKER:-/usr/local/bin/docker}"
TEMPLATE=demo_template

if [ -n "$PG_REMOTE" ]; then
    PG_ADDR="${PG_ADDR:?PG_ADDR (the remote address apps connect to) is required with PG_REMOTE}"
    # One multiplexed ssh connection, so the per-level CPU samples cost a round trip, not a handshake.
    # shellcheck disable=SC2206
    SSH=($PG_SSH -o BatchMode=yes -o ControlMaster=auto -o "ControlPath=/tmp/bfc-pg-%r@%h:%p" -o ControlPersist=300)
    dk() { "${SSH[@]}" "$PG_REMOTE" "$PG_REMOTE_DOCKER" "$(printf '%q ' "$@")"; }
else
    PG_ADDR=127.0.0.1
    dk() { docker "$@"; }
fi

psql_() { dk exec -i -e PGPASSWORD=bench "$PG_CONTAINER" psql -h 127.0.0.1 -p "$PG_PORT" -U bench -v ON_ERROR_STOP=1 -X -q "$@"; }

ready() { dk exec "$PG_CONTAINER" pg_isready -q -h 127.0.0.1 -p "$PG_PORT" -U bench 2>/dev/null; }

start() {
    if [ "$(dk inspect -f '{{.State.Running}}' "$PG_CONTAINER" 2>/dev/null)" != true ]; then
        dk rm -f "$PG_CONTAINER" >/dev/null 2>&1 || true
        local net
        if [ -n "$PG_REMOTE" ]; then
            net=(-p "$PG_ADDR:$PG_PORT:$PG_PORT")
        else
            net=(--network host ${PG_CPUS:+--cpuset-cpus="$PG_CPUS"})
        fi
        # max_connections leaves room for the largest pool (32 php-fpm workers, or a 32-connection
        # pool) plus test and admin sessions. fsync and synchronous_commit stay at their defaults.
        dk run -d --name "$PG_CONTAINER" "${net[@]}" \
            --memory="$PG_MEMORY" --shm-size=1g --ulimit nofile=65535:65535 \
            -e POSTGRES_USER=bench -e POSTGRES_PASSWORD=bench -e POSTGRES_DB=postgres \
            "$PG_IMAGE" -c port="$PG_PORT" -c max_connections=300 -c shared_buffers=512MB \
            -c listen_addresses="$([ -n "$PG_REMOTE" ] && echo '*' || echo 127.0.0.1)" >/dev/null
    elif [ -z "$PG_REMOTE" ] && [ -n "$PG_CPUS" ]; then
        # Already running (e.g. started by test.sh): re-pin it to the cores this run reserved.
        docker update --cpuset-cpus="$PG_CPUS" "$PG_CONTAINER" >/dev/null
    fi
    # The image's init phase runs a socket-only server, so a TCP probe means the real one is up.
    for _ in $(seq 1 120); do ready && break; sleep 0.5; done
    ready || { echo "postgres did not become ready" >&2; dk logs --tail 20 "$PG_CONTAINER" >&2; exit 1; }

    local want have
    want="$(md5sum <"$HERE/generate.sql" | cut -c1-32)"
    have="$(psql_ -d postgres -tA -c "select shobj_description(oid, 'pg_database') from pg_database where datname = '$TEMPLATE'")"
    if [ "$want" != "$have" ]; then
        echo "loading $TEMPLATE from db/generate.sql" >&2
        psql_ -d postgres -c "drop database if exists $TEMPLATE with (force)" -c "create database $TEMPLATE"
        psql_ -d "$TEMPLATE" -f - <"$HERE/generate.sql"
        psql_ -d postgres -c "comment on database $TEMPLATE is '$want'"
    fi
}

reset() {
    local name="${1:?usage: $0 reset NAME}"
    [[ "$name" =~ ^[a-z_][a-z0-9_]*$ ]] || { echo "bad database name: $name" >&2; exit 2; }
    psql_ -d postgres -c "drop database if exists $name with (force)" -c "create database $name template $TEMPLATE"
}

case "${1:-}" in
    start) start ;;
    reset) shift; reset "$@" ;;
    psql) shift; psql_ "$@" ;;
    host) echo "$PG_ADDR" ;;
    cpu) dk exec "$PG_CONTAINER" cat /sys/fs/cgroup/cpu.stat 2>/dev/null | awk '/^usage_usec/ {print $2}' ;;
    stop) dk rm -f "$PG_CONTAINER" >/dev/null 2>&1 || true ;;
    *) sed -n '2,22p' "$0" >&2; exit 2 ;;
esac
