#!/usr/bin/env bash
# Node / Hono (@hono/node-server) / Drizzle (node-postgres). tsc compiles src/ to dist/.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NAME="${NAME:-node-hono}"
STACK="${STACK:-Node/Hono/Drizzle}"
PORT="${PORT:-3002}"
BENCH_PATH="${BENCH_PATH:-/api/contents?pageSize=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/api/contents?pageSize={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/api/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/api/categories'
# PostgreSQL connection (db/postgres.sh); the harness overrides these per run.
export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-5432}" PGUSER="${PGUSER:-bench}" PGPASSWORD="${PGPASSWORD:-bench}"
export PGDATABASE="${PGDATABASE:-demo}" DB_POOL_SIZE="${DB_POOL_SIZE:-32}"
export DATABASE_URL="${DATABASE_URL:-postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE}"
# Server processes (one JS thread each), one per core of the 4-core container.
export WORKERS="${WORKERS:-4}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        ;;
    check)
        command -v node >/dev/null 2>&1 || { echo "node not found" >&2; exit 1; }
        command -v npm >/dev/null 2>&1 || { echo "npm not found" >&2; exit 1; }
        ;;
    build)
        cd "$HERE"
        npm install --no-audit --no-fund
        npm run build
        ;;
    start)
        cd "$HERE"
        export PORT
        exec node dist/index.js
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
