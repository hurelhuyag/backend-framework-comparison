#!/usr/bin/env bash
# Go / Gorilla / GORM. NOTE: the listen port is hardcoded to 8080 in main.go;
# change it there too if you change PORT here.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

NAME="${NAME:-go}"
STACK="${STACK:-Go/Gorm/Gorilla}"
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
        cd "$HERE" && CGO_ENABLED=1 go build -ldflags="-s -w" -o myapp main.go
        ;;
    start)
        # main.go opens "demo.sqlite" relative to the cwd, so start from the repo root.
        cd "$ROOT"
        exec "$HERE/myapp"
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
