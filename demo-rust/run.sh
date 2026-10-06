#!/usr/bin/env bash
# Rust / Axum / SeaORM. Customize by editing the vars below or exporting them.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

NAME="${NAME:-rust}"
STACK="${STACK:-Rust1.99/Axum0.8/SeaORM2.0}"
PORT="${PORT:-8081}"
BENCH_PATH="${BENCH_PATH:-/api/contents?size=20}"
DEMO_DB="${DEMO_DB:-$ROOT/demo.sqlite}"
CARGO="${CARGO:-$HOME/.cargo/bin/cargo}"

case "${1:-start}" in
    meta)
        printf 'NAME=%s\nSTACK=%s\nPORT=%s\nBENCH_PATH=%s\n' "$NAME" "$STACK" "$PORT" "$BENCH_PATH"
        ;;
    check)
        command -v "$CARGO" >/dev/null 2>&1 || { echo "cargo not found (set CARGO=)" >&2; exit 1; }
        ;;
    build)
        cd "$HERE" && "$CARGO" build --release
        ;;
    start)
        cd "$HERE"
        exec env DATABASE_URL="sqlite://$DEMO_DB" PORT="$PORT" ./target/release/demo-rust
        ;;
    *)
        echo "usage: $0 {meta|check|build|start}" >&2; exit 2
        ;;
esac
