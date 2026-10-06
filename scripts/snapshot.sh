#!/bin/bash
# Runs image snapshot tests on a pinned iOS simulator, one package after another.
# A package takes part when it has a test target folder Tests/<package name>SnapshotTests.
# Usage: scripts/snapshot.sh [package dir ...] [options]
#   no package dir    run every package under Modules/ that has a snapshot target
#   --only Class[/test]  run one class or test (needs exactly one package dir)
#   --record          write new reference images instead of comparing
#   --sim UDID        simulator (default: the "MEGA Snapshots" simulator, created when missing)
# Output per package in derivedData/snapshots/<target>-<time stamp>: result.xcresult, xcodebuild.log
# and failures/ with the images of each failed compare.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES=()
ONLY=""
RECORD="never"
SIM=""

while [ $# -gt 0 ]; do
    case "$1" in
        --only) ONLY="$2"; shift 2 ;;
        --record) RECORD="all"; shift ;;
        --sim) SIM="$2"; shift 2 ;;
        -*) echo "Unknown option $1"; exit 2 ;;
        *) PACKAGES+=("$1"); shift ;;
    esac
done

if [ ${#PACKAGES[@]} -eq 0 ]; then
    for manifest in "$ROOT"/Modules/*/*/Package.swift; do
        dir="$(dirname "$manifest")"
        [ -d "$dir/Tests/$(basename "$dir")SnapshotTests" ] && PACKAGES+=("$dir")
    done
fi
if [ ${#PACKAGES[@]} -eq 0 ]; then
    echo "No package with a snapshot target found."
    exit 2
fi
if [ -n "$ONLY" ] && [ ${#PACKAGES[@]} -ne 1 ]; then
    echo "--only needs exactly one package dir."
    exit 2
fi

# The reference images were made on this runtime, at 3x, with the default text size.
if [ -z "$SIM" ]; then
    SIM="$(xcrun simctl list devices available | grep "MEGA Snapshots (" | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}" | head -1)"
fi
if [ -z "$SIM" ]; then
    SIM="$(xcrun simctl create "MEGA Snapshots" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro com.apple.CoreSimulator.SimRuntime.iOS-26-4)" || {
        echo "Could not create the simulator. Install the iOS 26.4 runtime or pass --sim <udid>."
        exit 2
    }
fi
xcrun simctl boot "$SIM" > /dev/null 2>&1
xcrun simctl bootstatus "$SIM" > /dev/null 2>&1
xcrun simctl ui "$SIM" content_size large
# A new simulator copies the Mac's languages. Some languages, such as Vietnamese, make text lines taller.
xcrun simctl spawn "$SIM" defaults write -g AppleLanguages -array en
xcrun simctl spawn "$SIM" defaults write -g AppleLocale -string en_US
# The images depend on these, so a failed compare on another machine starts by comparing this line.
RUNTIME="$(xcrun simctl getenv "$SIM" SIMULATOR_RUNTIME_VERSION 2>&1) ($(xcrun simctl getenv "$SIM" SIMULATOR_RUNTIME_BUILD_VERSION 2>&1))"
XCODE="$(xcodebuild -version 2>&1 | tr '\n' ' ' | sed 's/ *$//')"
LANGUAGES="$(xcrun simctl spawn "$SIM" defaults read -g AppleLanguages 2>&1 | tr -d ' \n')"
echo "Simulator runtime: iOS $RUNTIME. Languages: $LANGUAGES. $XCODE. Host: $(sysctl -n hw.model 2>&1)."

# TEST_RUNNER_ variables reach the test process without the prefix.
# MEGA_SNAPSHOT turns on tests with the .snapshot trait. SNAPSHOT_TESTING_RECORD is read by the snapshot library.
export TEST_RUNNER_MEGA_SNAPSHOT=1
export TEST_RUNNER_SNAPSHOT_TESTING_RECORD="$RECORD"

FAILED=()
for package in "${PACKAGES[@]}"; do
    package="$(cd "$package" && pwd)"
    name="$(basename "$package")"
    target="${name}SnapshotTests"
    # A package with several products gets a "-Package" scheme from Xcode. One product gets only the package name.
    if (cd "$package" && xcodebuild -list 2>&1) | grep -q "^ *$name-Package\$"; then
        scheme="$name-Package"
    else
        scheme="$name"
    fi
    out="$ROOT/derivedData/snapshots/$target-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$out/failures"
    # The library writes the new image and the difference image of a failed compare here.
    export TEST_RUNNER_SNAPSHOT_ARTIFACTS="$out/failures"

    echo "== $target on simulator $SIM (record: $RECORD) =="
    # One test at a time: parallel runs use simulator clones, which do not keep the text size.
    (cd "$package" && xcodebuild test \
        -scheme "$scheme" \
        -only-testing:"$target${ONLY:+/$ONLY}" \
        -destination "platform=iOS Simulator,id=$SIM" \
        -derivedDataPath "$ROOT/derivedData/snapshots/build" \
        -resultBundlePath "$out/result.xcresult" \
        -parallel-testing-enabled NO \
        -enableCodeCoverage NO \
        -skipPackagePluginValidation \
        SWIFT_SUPPRESS_WARNINGS=NO) > "$out/xcodebuild.log" 2>&1
    status=$?
    if [ $status -ne 0 ]; then
        grep -E "error:|failed after" "$out/xcodebuild.log" | head -30
        # The console shows only the first line of an issue. The result bundle has the reason:
        # a size change ("does not match reference@") or a pixel change ("percentage of pixels").
        xcrun xcresulttool get test-results tests --path "$out/result.xcresult" 2>&1 \
            | grep '"name" : ".*Issue recorded: ' \
            | awk '{ gsub(/\\n/, "\n"); gsub(/\\"/, "\""); print }' \
            | grep -E "Issue recorded: |does not match reference@|percentage of pixels|perceptual color precision|Snapshots need|could not be loaded|is empty" \
            | sed -e 's/^ *"name" : "//' -e 's/",*$//' \
            | head -80
        echo "$target failed: xcodebuild exit $status (see $out/xcodebuild.log)"
        FAILED+=("$target")
    else
        echo "$target passed"
    fi
done

if [ ${#FAILED[@]} -ne 0 ]; then
    echo "Failed: ${FAILED[*]}"
    exit 1
fi
