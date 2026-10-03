#!/usr/bin/env bash
# Performance benchmark script
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
NVIM=${NVIM:-nvim}
APP_NAME=$(basename "$ROOT")

echo "=== Startup Time (5 runs) ==="
for i in {1..5}; do
    /usr/bin/time -f "%E real" \
        XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$APP_NAME" \
        "$NVIM" --headless +qa 2>&1 | grep -E '^[0-9:]'
done

echo ""
echo "=== Lazy Profile ==="
XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$APP_NAME" \
    "$NVIM" --headless "+Lazy profile" +qa 2>&1 | head -40

echo ""
echo "=== Memory Estimate ==="
XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$APP_NAME" \
    "$NVIM" --headless "+lua print(collectgarbage('count')..' KB')" +qa 2>&1