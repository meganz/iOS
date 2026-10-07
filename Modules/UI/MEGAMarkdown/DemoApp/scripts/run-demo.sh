#!/bin/bash
# Builds the demo app, installs it and launches it.
# Usage:
#   scripts/run-demo.sh <simulator-udid>
#   scripts/run-demo.sh --device <device-udid>   (needs a signing team set in Xcode first)
# The app downloads the test files itself: tap Sync on the first screen.
set -eu

DEMO="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(git -C "$DEMO" rev-parse --show-toplevel)"
# derivedData/ is ignored by git, so build output never lands in tracked paths.
DD="$REPO/derivedData/markdown-demo"
LOG="$REPO/derivedData/markdown-demo-build.log"
BUNDLE_ID="$(grep -m1 'PRODUCT_BUNDLE_IDENTIFIER' "$DEMO/MEGAMarkdownDemo.xcodeproj/project.pbxproj" | sed 's/.*= \(.*\);/\1/')"
mkdir -p "$REPO/derivedData"

if [ "${1:-}" = "--device" ]; then
    DEVICE_ID="$2"
    DESTINATION="id=$DEVICE_ID"
    PRODUCTS="Debug-iphoneos"
    EXTRA=(-allowProvisioningUpdates)
else
    SIM_ID="${1:?simulator udid required}"
    DESTINATION="id=$SIM_ID"
    PRODUCTS="Debug-iphonesimulator"
    EXTRA=()
    xcrun simctl boot "$SIM_ID" 2>/dev/null || true
fi

echo "== Build =="
if ! xcodebuild build \
    -project "$DEMO/MEGAMarkdownDemo.xcodeproj" \
    -scheme MEGAMarkdownDemo \
    -destination "$DESTINATION" \
    -derivedDataPath "$DD" \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    ${EXTRA[@]+"${EXTRA[@]}"} \
    SWIFT_SUPPRESS_WARNINGS=NO \
    > "$LOG" 2>&1; then
    grep -E "error:" "$LOG" | head -20
    echo "BUILD FAILED (see $LOG)"
    exit 1
fi
echo "BUILD SUCCEEDED"

APP="$DD/Build/Products/$PRODUCTS/MEGAMarkdownDemo.app"
echo "== Install and launch =="
if [ "${1:-}" = "--device" ]; then
    xcrun devicectl device install app --device "$DEVICE_ID" "$APP"
    xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID"
else
    xcrun simctl install "$SIM_ID" "$APP"
    xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl launch "$SIM_ID" "$BUNDLE_ID"
fi
