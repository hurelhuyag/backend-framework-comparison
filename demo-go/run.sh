#!/usr/bin/env bash
# Go / Gin / GORM. The server reads PORT from the environment (default 8080).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-5432}" PGUSER="${PGUSER:-bench}"
export PGPASSWORD="${PGPASSWORD:-bench}" PGDATABASE="${PGDATABASE:-demo}"
export DATABASE_URL="${DATABASE_URL:-postgres://bench:bench@127.0.0.1:5432/demo}"
export DB_POOL_SIZE="${DB_POOL_SIZE:-32}"

NAME="${NAME:-go}"
STACK="${STACK:-Go/Gin/Gorm}"
PORT="${PORT:-8080}"
BENCH_PATH="${BENCH_PATH:-/contents?size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/contents?size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/categories'

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        ;;
    check)
        command -v go >/dev/null 2>&1 || { echo "go not found" >&2; exit 1; }
        ;;
    build)
        cd "$HERE" && CGO_ENABLED=0 go build -ldflags="-s -w" -o myapp ./cmd/server
        ;;
    start)
        cd "$ROOT"
        PORT="$PORT" exec "$HERE/myapp"
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
