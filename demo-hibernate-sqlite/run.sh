#!/usr/bin/env bash
# Java / Spring Boot / Hibernate. Set NATIVE=1 to build+run the GraalVM native image
# instead of the JVM jar (needs a GraalVM JDK on JAVA_HOME).
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

NATIVE="${NATIVE:-0}"
NAME="${NAME:-java}"
if [ "$NATIVE" = "1" ]; then
    STACK="${STACK:-GraalVM-JDK25/Spring4.1/Hibernate7 (native)}"
else
    STACK="${STACK:-OpenJDK27/Spring4.1/Hibernate7}"
fi
PORT="${PORT:-8080}"
BENCH_PATH="${BENCH_PATH:-/contents?size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/contents?size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/categories'
JAVA_OPTS="${JAVA_OPTS:-}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        ;;
    check)
        command -v mvn >/dev/null 2>&1 || { echo "mvn not found" >&2; exit 1; }
        command -v java >/dev/null 2>&1 || { echo "java not found" >&2; exit 1; }
        ;;
    build)
        cd "$HERE"
        if [ "$NATIVE" = "1" ]; then
            mvn -B -DskipTests -Pnative clean compile package native:compile
        else
            mvn -B -DskipTests clean package
        fi
        ;;
    start)
        cd "$ROOT"
        if [ "$NATIVE" = "1" ]; then
            exec "$HERE/target/demo-hibernate-sqlite" --server.port="$PORT"
        fi
        jar="$(ls -1 "$HERE"/target/*.jar 2>/dev/null | grep -v '\.original$' | head -1)"
        [ -n "$jar" ] || { echo "no jar in $HERE/target - run './run.sh build'" >&2; exit 1; }
        exec java $JAVA_OPTS -jar "$jar" --server.port="$PORT"
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
