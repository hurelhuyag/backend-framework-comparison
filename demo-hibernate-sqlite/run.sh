#!/usr/bin/env bash
# Java / Spring Boot / Hibernate. Set NATIVE=1 to build+run the GraalVM native image
# instead of the JVM jar (needs a GraalVM JDK on JAVA_HOME).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

NATIVE="${NATIVE:-0}"
NAME="${NAME:-java}"
if [ "$NATIVE" = "1" ]; then
    STACK="${STACK:-GraalVM25/Spring4.1/Hibernate7 (native)}"
else
    STACK="${STACK:-OpenJDK25/Spring4.1/Hibernate7}"
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
        # application.properties uses jdbc:sqlite:demo.sqlite (relative), so start from the repo root.
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
