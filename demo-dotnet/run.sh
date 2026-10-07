#!/usr/bin/env bash
# C# / ASP.NET Core Minimal APIs / EF Core. Customize by editing the vars below or exporting them.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

NAME="${NAME:-dotnet}"
STACK="${STACK:-DotNet10/AspNetCore/EFCore}"
PORT="${PORT:-8082}"
BENCH_PATH="${BENCH_PATH:-/api/contents?size=20}"
LIST_PATH="${LIST_PATH-}"
[ -n "$LIST_PATH" ] || LIST_PATH='/api/contents?size={size}'
ITEM_PATH="${ITEM_PATH-}"
[ -n "$ITEM_PATH" ] || ITEM_PATH='/api/contents/{id}'
CATEGORIES_PATH="${CATEGORIES_PATH-}"
NOTES="${NOTES-}"
[ -n "$NOTES" ] || NOTES='1 query/read; hand-written repository + Mapster + FluentValidation'
[ -n "$CATEGORIES_PATH" ] || CATEGORIES_PATH='/api/categories'
DEMO_DB="${DEMO_DB:-$ROOT/demo.sqlite}"
DOTNET="${DOTNET:-dotnet}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        printf 'LIST_PATH=%s\nITEM_PATH=%s\nCATEGORIES_PATH=%s\n' "$LIST_PATH" "$ITEM_PATH" "$CATEGORIES_PATH"
        printf 'NOTES=%s\n' "$NOTES"
        ;;
    check)
        command -v "$DOTNET" >/dev/null 2>&1 || { echo "dotnet not found (set DOTNET=)" >&2; exit 1; }
        ;;
    build)
        cd "$HERE" && "$DOTNET" publish -c Release -o ./publish
        ;;
    start)
        cd "$HERE"
        exec env DEMO_DB="$DEMO_DB" ASPNETCORE_URLS="http://0.0.0.0:$PORT" ./publish/demo-dotnet
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
