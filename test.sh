#!/usr/bin/env bash
# Runs every demo's endpoint tests, each in its own container.
#
#   ./test.sh              all demos
#   ./test.sh go rust      just those (directory names without the demo- prefix)
#
# Each demo-*/Dockerfile has a `test` stage. Its container runs on the host network against the
# bfc-postgres server (db/postgres.sh), in its own database test_<demo> cloned fresh from
# demo_template for that run, so a test run never shares data with a benchmark or another demo.
# The connection is passed as DATABASE_URL plus the libpq PG* variables (see db/postgres.sh).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [ $# -gt 0 ]; then
    demos=("$@")
else
    demos=()
    for dockerfile in demo-*/Dockerfile; do
        grep -q ' AS test$' "$dockerfile" && demos+=("$(basename "$(dirname "$dockerfile")" | sed 's/^demo-//')")
    done
fi

PG_PORT="${PG_PORT:-5432}"
db/postgres.sh start || exit 1
PG_HOST="$(db/postgres.sh host)"

declare -A RESULT
for demo in "${demos[@]}"; do
    image="bfc-$demo:test"
    echo "=== $demo"
    if ! docker build -q -f "demo-$demo/Dockerfile" --target test -t "$image" . >/dev/null; then
        echo "    build failed (rerun: docker build -f demo-$demo/Dockerfile --target test .)"
        RESULT[$demo]="BUILD FAILED"
        continue
    fi
    db="test_${demo//-/_}"
    db/postgres.sh reset "$db" >/dev/null || { RESULT[$demo]="DB RESET FAILED"; continue; }
    if docker run --rm --network host --ulimit nofile=65535:65535 \
            -e DATABASE_URL="postgres://bench:bench@$PG_HOST:$PG_PORT/$db" \
            -e PGHOST="$PG_HOST" -e PGPORT="$PG_PORT" -e PGUSER=bench -e PGPASSWORD=bench -e PGDATABASE="$db" \
            "$image"; then
        RESULT[$demo]="passed"
    else
        RESULT[$demo]="FAILED"
    fi
    echo
done

echo "=== summary"
status=0
for demo in "${demos[@]}"; do
    printf '%-20s %s\n' "$demo" "${RESULT[$demo]}"
    [ "${RESULT[$demo]}" = passed ] || status=1
done
exit $status
