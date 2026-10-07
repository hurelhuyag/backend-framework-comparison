#!/usr/bin/env bash
# FrankenPHP / Laravel Octane (worker mode). The application is ../demo-php; this directory only
# holds how it is served. Docker is the supported way to run it (see Dockerfile).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
# In the image the app is copied next to this script; on the host it lives in ../demo-php.
APP="${APP:-$([ -f "$HERE/artisan" ] && echo "$HERE" || echo "$ROOT/demo-php")}"

NAME="${NAME:-frankenphp}"
STACK="${STACK:-FrankenPHP/Php8.4/Laravel (Octane)}"
PORT="${PORT:-8004}"
BENCH_PATH="${BENCH_PATH:-/api/contents?page_size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/api/contents?page_size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/api/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/api/categories'
# PostgreSQL connection (shared contract with the harness). Laravel's pgsql connection reads the
# PG* variables (config/database.php). Each Octane worker keeps its connection open between
# requests, so the connection count is the worker count; DB_POOL_SIZE is exported for parity only.
export DATABASE_URL="${DATABASE_URL:-postgres://bench:bench@127.0.0.1:5432/demo}"
export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-5432}" PGUSER="${PGUSER:-bench}"
export PGPASSWORD="${PGPASSWORD:-bench}" PGDATABASE="${PGDATABASE:-demo}"
export DB_POOL_SIZE="${DB_POOL_SIZE:-32}"
export DB_CONNECTION=pgsql OCTANE_SERVER=frankenphp
# Octane's defaults: workers=auto (FrankenPHP picks 2 per CPU), each worker restarts after 500 requests.
WORKERS="${WORKERS:-auto}"
MAX_REQUESTS="${MAX_REQUESTS:-500}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        ;;
    check)
        command -v frankenphp >/dev/null 2>&1 || { echo "frankenphp not found (use the Docker image)" >&2; exit 1; }
        ;;
    build)
        cd "$APP"
        composer install --no-interaction --no-dev --optimize-autoloader
        [ -f .env ] || cp .env.example .env
        ;;
    start)
        cd "$APP"
        # The config cache freezes env() values, so build it from this container's environment.
        php artisan config:cache >/dev/null
        exec php artisan octane:frankenphp --host=0.0.0.0 --port="$PORT" \
            --workers="$WORKERS" --max-requests="$MAX_REQUESTS"
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
