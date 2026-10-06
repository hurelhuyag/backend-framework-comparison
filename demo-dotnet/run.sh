#!/usr/bin/env bash
# C# / ASP.NET Core Minimal APIs / EF Core. Customize by editing the vars below or exporting them.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

NAME="${NAME:-dotnet}"
STACK="${STACK:-DotNet10/AspNetCore/EFCore}"
PORT="${PORT:-8082}"
BENCH_PATH="${BENCH_PATH:-/api/contents?size=20}"
DEMO_DB="${DEMO_DB:-$ROOT/demo.sqlite}"
DOTNET="${DOTNET:-dotnet}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
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
