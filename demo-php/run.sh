#!/usr/bin/env bash
# PHP / Laravel.
#
# WARNING: `php artisan serve` (the default here) is the single-threaded PHP dev server.
# It is NOT comparable to the Nginx/PHP-FPM number in the root README. For a real
# measurement, serve public/ through Nginx + PHP-FPM and point this at that port with
# PHP_SERVER=external PORT=<nginx port>.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

NAME="${NAME:-php}"
PHP_SERVER="${PHP_SERVER:-artisan}"
if [ "$PHP_SERVER" = "fpm" ] || [ "$PHP_SERVER" = "external" ]; then
    STACK="${STACK:-Nginx/Php8.4/Laravel}"
else
    STACK="${STACK:-Php/Laravel (artisan dev server)}"
fi
PORT="${PORT:-8001}"
BENCH_PATH="${BENCH_PATH:-/api/contents?page_size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/api/contents?page_size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/api/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/api/categories'
# PostgreSQL connection (shared contract with the harness). Laravel's pgsql connection reads the
# PG* variables (config/database.php); DATABASE_URL and DB_POOL_SIZE are exported for parity only
# (php-fpm keeps one persistent PDO connection per worker instead of a pool).
export DATABASE_URL="${DATABASE_URL:-postgres://bench:bench@127.0.0.1:5432/demo}"
export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-5432}" PGUSER="${PGUSER:-bench}"
export PGPASSWORD="${PGPASSWORD:-bench}" PGDATABASE="${PGDATABASE:-demo}"
export DB_POOL_SIZE="${DB_POOL_SIZE:-32}"
export DB_CONNECTION=pgsql

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        ;;
    check)
        if [ "$PHP_SERVER" = "external" ]; then exit 0; fi
        if [ "$PHP_SERVER" = "fpm" ]; then
            command -v php-fpm >/dev/null 2>&1 || { echo "php-fpm not found" >&2; exit 1; }
            exit 0
        fi
        command -v php >/dev/null 2>&1 || { echo "php not found" >&2; exit 1; }
        command -v composer >/dev/null 2>&1 || { echo "composer not found" >&2; exit 1; }
        ;;
    build)
        if [ "$PHP_SERVER" = "external" ] || [ "$PHP_SERVER" = "fpm" ]; then exit 0; fi
        cd "$HERE"
        composer install --no-interaction --no-dev --optimize-autoloader
        [ -f .env ] || cp .env.example .env
        ;;
    start)
        if [ "$PHP_SERVER" = "fpm" ]; then
            # Nginx + PHP-FPM (what the Docker image uses).
            # nginx.conf has a literal `listen`; point it at $PORT.
            sed -i "s/^\( *listen \)[0-9]*/\1$PORT/" /etc/nginx/nginx.conf 2>/dev/null || true
            # The config cache freezes env() values, so build it here, from the PG* this container
            # was started with, not at image build time.
            (cd "$HERE" && php artisan config:cache >/dev/null)
            php-fpm -D
            exec nginx -g 'daemon off;'
        fi
        if [ "$PHP_SERVER" = "external" ]; then
            echo "PHP_SERVER=external: expecting an already-running Nginx/PHP-FPM on port $PORT"
            # Nothing to launch; hold the slot open so the harness can benchmark the external server.
            exec sleep infinity
        fi
        cd "$HERE"
        exec php artisan serve --host=0.0.0.0 --port="$PORT"
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
