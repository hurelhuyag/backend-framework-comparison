#!/usr/bin/env bash
# Bun with no framework and no ORM: Bun.serve routes and plain SQL through Bun.SQL (PostgreSQL).
# Bun runs the TypeScript sources directly; there is no build output.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NAME="${NAME:-bun}"
STACK="${STACK:-Bun/Bun.serve/Bun.SQL}"
PORT="${PORT:-3003}"
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
        command -v bun >/dev/null 2>&1 || { echo "bun not found" >&2; exit 1; }
        ;;
    build)
        cd "$HERE"
        bun install --frozen-lockfile
        ;;
    start)
        cd "$HERE"
        export PORT
        exec bun src/index.ts
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
