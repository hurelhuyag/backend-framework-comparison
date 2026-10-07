#!/usr/bin/env bash
# Go / Gin / GORM. The server reads PORT from the environment (default 8080).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
DEMO_DB="${DEMO_DB:-$ROOT/demo.sqlite}"

NAME="${NAME:-go}"
STACK="${STACK:-Go/Gin/Gorm}"
PORT="${PORT:-8080}"
BENCH_PATH="${BENCH_PATH:-/contents?size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/contents?size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
NOTES="${NOTES-}"
[ -n "$NOTES" ] || NOTES='full ORM; layered handler/service/repository'
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/categories'

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        printf 'NOTES=%s\n' "$NOTES"
        ;;
    check)
        command -v go >/dev/null 2>&1 || { echo "go not found" >&2; exit 1; }
        ;;
    build)
        cd "$HERE" && CGO_ENABLED=1 go build -ldflags="-s -w" -o myapp ./cmd/server
        ;;
    start)
        cd "$ROOT"
        DEMO_DB="$DEMO_DB" PORT="$PORT" exec "$HERE/myapp"
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
