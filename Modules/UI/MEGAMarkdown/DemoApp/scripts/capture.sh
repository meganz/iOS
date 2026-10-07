#!/bin/bash
# Opens every test file in the demo app on a simulator, saves screenshots, and makes contact sheets.
# Usage: scripts/capture.sh <simulator-udid> [path prefix, for example images/] [max screens per file]
# Output: derivedData/markdown-captures/<prefix, or "all">/ (PNGs, index.json) and its sheets/ folder.
# Each prefix has its own folder, so a run for one folder does not replace a full run.
set -eu

SIM_ID="${1:?simulator udid required}"
PREFIX="${2:-}"
PAGES="${3:-4}"
DEMO="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(git -C "$DEMO" rev-parse --show-toplevel)"
OUT_NAME="$(printf '%s' "${PREFIX:-all}" | tr '/' '_')"
OUT="$REPO/derivedData/markdown-captures/$OUT_NAME"
BUNDLE_ID="$(grep -m1 'PRODUCT_BUNDLE_IDENTIFIER' "$DEMO/MEGAMarkdownDemo.xcodeproj/project.pbxproj" | sed 's/.*= \(.*\);/\1/')"

# Builds, installs and launches the app once. The capture launch below replaces that process.
bash "$DEMO/scripts/run-demo.sh" "$SIM_ID" > /dev/null
# The same clock and bars on every screenshot.
xcrun simctl status_bar "$SIM_ID" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3

CAPTURES="$(xcrun simctl get_app_container "$SIM_ID" "$BUNDLE_ID" data)/Documents/Captures"
xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" 2>/dev/null || true
echo "== Capture ${PREFIX:-all files} =="
STARTED="$(date +%s)"
xcrun simctl launch "$SIM_ID" "$BUNDLE_ID" -capture -capture-prefix "$PREFIX" -capture-pages "$PAGES" > /dev/null

# A new index.json appears when the run is done. An older one is from an earlier run.
is_done() {
    [ -f "$CAPTURES/index.json" ] && [ "$(stat -f %m "$CAPTURES/index.json")" -ge "$STARTED" ]
}
# Stops after 60 minutes.
for _ in $(seq 1 3600); do
    is_done && break
    sleep 1
done
if ! is_done; then
    echo "CAPTURE TIMED OUT"
    exit 1
fi

mkdir -p "$OUT"
rsync -a --delete "$CAPTURES/" "$OUT/"
python3 "$DEMO/scripts/make_contact_sheets.py" "$OUT"
echo "CAPTURE DONE: $OUT"
