#!/usr/bin/env bash
# GraalVM native image of the Spring/Hibernate demo.
#
# This directory holds no Java source: it builds a native binary from the sources in
# ../demo-hibernate-sqlite, so the JVM row and the native row compare the SAME application.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
DEMO_DB="${DEMO_DB:-$ROOT/demo.sqlite}"

NAME="${NAME:-graalvm}"
STACK="${STACK:-GraalVM-JDK25/Spring4.1/Hibernate7 (native)}"
PORT="${PORT:-8083}"
BENCH_PATH="${BENCH_PATH:-/contents?size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/contents?size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
NOTES="${NOTES-}"
[ -n "$NOTES" ] || NOTES='AOT: needs no warmup, but has no JIT ceiling either; same source as java'
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/categories'
APP="${APP:-$HERE/demo-graalvm-app}"
SRC="${SRC:-$ROOT/demo-hibernate-sqlite}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        printf 'NOTES=%s\n' "$NOTES"
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
        exec "$APP" --server.port="$PORT" --spring.datasource.url="jdbc:sqlite:$DEMO_DB"
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
