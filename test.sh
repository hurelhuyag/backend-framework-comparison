#!/usr/bin/env bash
# Runs every demo's endpoint tests, each in its own container.
#
#   ./test.sh              all demos
#   ./test.sh go rust      just those (directory names without the demo- prefix)
#
# Each demo-*/Dockerfile has a `test` stage that copies demo.sqlite into the image, so a test run
# never reads or writes the repo's database and never shares one with another demo.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [ $# -gt 0 ]; then
    demos=("$@")
else
    demos=()
    for dockerfile in demo-*/Dockerfile; do
        grep -q ' AS test$' "$dockerfile" && demos+=("$(basename "$(dirname "$dockerfile")" | sed 's/^demo-//')")
    done
fi

declare -A RESULT
for demo in "${demos[@]}"; do
    image="bfc-$demo:test"
    echo "=== $demo"
    if ! docker build -q -f "demo-$demo/Dockerfile" --target test -t "$image" . >/dev/null; then
        echo "    build failed (rerun: docker build -f demo-$demo/Dockerfile --target test .)"
        RESULT[$demo]="BUILD FAILED"
        continue
    fi
    if docker run --rm "$image"; then
        RESULT[$demo]="passed"
    else
        RESULT[$demo]="FAILED"
    fi
    echo
done

echo "=== summary"
status=0
for demo in "${demos[@]}"; do
    printf '%-20s %s\n' "$demo" "${RESULT[$demo]}"
    [ "${RESULT[$demo]}" = passed ] || status=1
done
exit $status
