#!/usr/bin/env bash
# GraalVM native image of the Spring/Hibernate demo.
#
# This directory holds no Java source: it builds a native binary from the sources in
# ../demo-hibernate-sqlite, so the JVM row and the native row compare the SAME application.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
# PostgreSQL connection (see ../db/postgres.sh). Explicit PG* win, then DATABASE_URL
# (postgres://user:pass@host:port/db), then the defaults. application.properties builds the
# JDBC url and credentials from PG*, and the Hikari pool size from DB_POOL_SIZE.
DATABASE_URL="${DATABASE_URL:-postgres://bench:bench@127.0.0.1:5432/demo}"
if [[ "$DATABASE_URL" =~ ^postgres(ql)?://([^:@/]+)(:([^@/]*))?@([^:/]+)(:([0-9]+))?/([^?]+) ]]; then
    : "${PGUSER:=${BASH_REMATCH[2]}}" "${PGPASSWORD:=${BASH_REMATCH[4]}}"
    : "${PGHOST:=${BASH_REMATCH[5]}}" "${PGPORT:=${BASH_REMATCH[7]:-5432}}" "${PGDATABASE:=${BASH_REMATCH[8]}}"
fi
export DATABASE_URL PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-5432}" PGUSER="${PGUSER:-bench}" \
    PGPASSWORD="${PGPASSWORD:-bench}" PGDATABASE="${PGDATABASE:-demo}" DB_POOL_SIZE="${DB_POOL_SIZE:-32}"

NAME="${NAME:-graalvm}"
STACK="${STACK:-GraalVM-JDK25/Spring4.1/Hibernate7 (native)}"
PORT="${PORT:-8083}"
BENCH_PATH="${BENCH_PATH:-/contents?size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/contents?size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/categories'
APP="${APP:-$HERE/demo-graalvm-app}"
SRC="${SRC:-$ROOT/demo-hibernate-sqlite}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        ;;
    check)
        command -v native-image >/dev/null 2>&1 || { echo "native-image not found (needs a GraalVM JDK)" >&2; exit 1; }
        command -v mvn >/dev/null 2>&1 || { echo "mvn not found" >&2; exit 1; }
        ;;
    build)
        # -Pnative comes from spring-boot-starter-parent; this pom defines no profiles itself.
        cd "$SRC"
        mvn -B -DskipTests -Djava.version=25 -Pnative clean package native:compile
        cp "$SRC/target/demo-hibernate-sqlite" "$APP"
        ;;
    start)
        cd "$ROOT"
        exec "$APP" --server.port="$PORT"
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
