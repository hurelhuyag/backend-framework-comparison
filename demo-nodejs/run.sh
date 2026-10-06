#!/usr/bin/env bash
# Node / NextJS / Prisma. DATABASE_URL is forced to the repo-root demo.sqlite so this
# does not depend on the absolute path baked into .env.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

NAME="${NAME:-nodejs}"
STACK="${STACK:-Node/NextJS/Prisma}"
PORT="${PORT:-3000}"
BENCH_PATH="${BENCH_PATH:-/api/contents?pageSize=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/api/contents?pageSize={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/api/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/api/categories'
DEMO_DB="${DEMO_DB:-$ROOT/demo.sqlite}"
export DATABASE_URL="${DATABASE_URL:-file:$DEMO_DB}"

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
        npx prisma generate
        NODE_ENV=production npm run build
        ;;
    start)
        cd "$HERE"
        exec npx next start -p "$PORT"
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
