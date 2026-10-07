#!/usr/bin/env bash
# Bun / Hono / Drizzle. Customize by editing the vars below or exporting them.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

NAME="${NAME:-bun}"
STACK="${STACK:-Bun/Hono/Drizzle}"
PORT="${PORT:-8084}"
BENCH_PATH="${BENCH_PATH:-/api/contents?size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/api/contents?size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/api/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
NOTES="${NOTES-}"
[ -n "$NOTES" ] || NOTES='query builder, not an ORM; 1 query/read; 4 workers via SO_REUSEPORT'
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/api/categories'
DEMO_DB="${DEMO_DB:-$ROOT/demo.sqlite}"
BUN="${BUN:-bun}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        printf 'NOTES=%s\n' "$NOTES"
        ;;
    check)
        command -v "$BUN" >/dev/null 2>&1 || { echo "bun not found (set BUN=)" >&2; exit 1; }
        ;;
    build)
        cd "$HERE"
        "$BUN" install --frozen-lockfile 2>/dev/null || "$BUN" install
        # demo-nodejs ships precompiled JS via tsc; bundle here so neither JS demo pays a
        # transpile cost at startup that the other avoids.
        "$BUN" build src/index.ts --target=bun --outfile=dist/server.js
        ;;
    start)
        cd "$HERE"
        exec env DEMO_DB="$DEMO_DB" PORT="$PORT" "$BUN" dist/server.js
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
