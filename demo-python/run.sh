#!/usr/bin/env bash
# Python / Django / Gunicorn. Deps go into a local .venv; gunicorn is added on top of
# requirements.txt (which does not list it). WORKERS tunes the gunicorn worker count.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

NAME="${NAME:-python}"
STACK="${STACK:-Python/Django/Gunicorn}"
PORT="${PORT:-8000}"
BENCH_PATH="${BENCH_PATH:-/contents/?page_size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/contents/?page_size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/contents/{id}/'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
NOTES="${NOTES-}"
[ -n "$NOTES" ] || NOTES='gunicorn, 4 sync workers'
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/categories/'
DEMO_DB="${DEMO_DB:-$ROOT/demo.sqlite}"
WORKERS="${WORKERS:-4}"
VENV="${VENV:-$HERE/.venv}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        printf 'NOTES=%s\n' "$NOTES"
        ;;
    check)
        command -v python3 >/dev/null 2>&1 || { echo "python3 not found" >&2; exit 1; }
        ;;
    build)
        cd "$HERE"
        [ -d "$VENV" ] || python3 -m venv "$VENV"
        "$VENV/bin/pip" install -q --upgrade pip
        "$VENV/bin/pip" install -q -r requirements.txt gunicorn
        # settings.py points at BASE_DIR/demo.sqlite; link it to the shared db.
        [ -e "$HERE/demo.sqlite" ] || ln -s "$DEMO_DB" "$HERE/demo.sqlite"
        ;;
    start)
        cd "$HERE"
        DEMO_DB="$DEMO_DB" exec "$VENV/bin/gunicorn" mysite.wsgi:application \
            --bind "0.0.0.0:$PORT" \
            --workers "$WORKERS" \
            --log-level error
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
