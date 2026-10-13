#!/bin/bash
# Runs one package's XCTest benchmarks headless on an iOS simulator, then checks the numbers against a limits file.
# Usage: scripts/benchmark.sh <package dir> [options]
#   --scheme S        xcodebuild scheme (default: the package's "-Package" scheme, or the package name)
#   --target T        benchmark test target (default: <package name>Benchmarks)
#   --only Class[/test]  run one class or test of the target
#   --sim UDID        simulator (default: the first booted iPhone)
#   --sim-name NAME --sim-os VERSION  the simulator with this name and iOS version, created and booted when needed
#   --limits FILE     limits JSON (default: <package>/Tests/<target>/Limits.json when it exists)
#   --skipped FILE    skip list, {"Class/test": "reason"} (default: <package>/Tests/<target>/Skipped.json when it exists)
#   --base XCRESULT   an earlier result bundle to compare against
#   --max-regression PERCENT  with --base: fail when a metric average grows by more than this
#   --write-limits    write the limits file from this run (3x time and counts, 1.5x memory), not after a failed xcodebuild
#   --debug           Debug build (default: Release with testability, as Apple advises for performance tests)
#   --out DIR         output folder (default: derivedData/benchmarks/<target>-<time stamp>)
# Output: result.xcresult, xcodebuild.log, metrics.json and report.md in the output folder.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE=""
SCHEME=""
TARGET=""
ONLY=""
SIM=""
SIM_NAME=""
SIM_OS=""
SKIPPED=""
LIMITS=""
BASE=""
MAX_REGRESSION=""
WRITE_LIMITS=0
CONFIGURATION="Release"
OUT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --scheme) SCHEME="$2"; shift 2 ;;
        --target) TARGET="$2"; shift 2 ;;
        --only) ONLY="$2"; shift 2 ;;
        --sim) SIM="$2"; shift 2 ;;
        --sim-name) SIM_NAME="$2"; shift 2 ;;
        --sim-os) SIM_OS="$2"; shift 2 ;;
        --skipped) SKIPPED="$2"; shift 2 ;;
        --limits) LIMITS="$2"; shift 2 ;;
        --base) BASE="$2"; shift 2 ;;
        --max-regression) MAX_REGRESSION="$2"; shift 2 ;;
        --write-limits) WRITE_LIMITS=1; shift ;;
        --debug) CONFIGURATION="Debug"; shift ;;
        --out) OUT="$2"; shift 2 ;;
        -*) echo "Unknown option $1"; exit 2 ;;
        *) PACKAGE="$1"; shift ;;
    esac
done
if [ -z "$PACKAGE" ] || [ ! -f "$PACKAGE/Package.swift" ]; then
    echo "Usage: scripts/benchmark.sh <package dir> [options]"
    exit 2
fi
PACKAGE="$(cd "$PACKAGE" && pwd)"
NAME="$(basename "$PACKAGE")"
# A package with several products gets a "-Package" scheme from Xcode. One product gets only the package name.
if [ -z "$SCHEME" ]; then
    if (cd "$PACKAGE" && xcodebuild -list 2>&1) | grep -q "^ *$NAME-Package\$"; then
        SCHEME="$NAME-Package"
    else
        SCHEME="$NAME"
    fi
fi
[ -z "$TARGET" ] && TARGET="${NAME}Benchmarks"
[ -z "$LIMITS" ] && { [ -f "$PACKAGE/Tests/$TARGET/Limits.json" ] || [ $WRITE_LIMITS -eq 1 ]; } && LIMITS="$PACKAGE/Tests/$TARGET/Limits.json"
[ -z "$OUT" ] && OUT="$ROOT/derivedData/benchmarks/$TARGET-$(date +%Y%m%d-%H%M%S)"
[ -z "$SKIPPED" ] && [ -f "$PACKAGE/Tests/$TARGET/Skipped.json" ] && SKIPPED="$PACKAGE/Tests/$TARGET/Skipped.json"
# The limits were recorded on one simulator model and OS, so CI asks for that pair and never falls back to another.
if [ -n "$SIM_NAME" ] || [ -n "$SIM_OS" ]; then
    if [ -z "$SIM_NAME" ] || [ -z "$SIM_OS" ] || [ -n "$SIM" ]; then
        echo "--sim-name and --sim-os go together, and not with --sim."
        exit 2
    fi
    SIM="$(python3 "$ROOT/scripts/benchmark_ci.py" simulator --name "$SIM_NAME" --os "$SIM_OS")" || exit 2
    xcrun simctl bootstatus "$SIM" -b || exit 2
fi
if [ -z "$SIM" ]; then
    SIM="$(xcrun simctl list devices booted | grep -E "iPhone" | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}" | head -1)"
fi
if [ -z "$SIM" ]; then
    echo "No booted iPhone simulator. Boot one or pass --sim <udid>."
    exit 2
fi
mkdir -p "$OUT"
# xcodebuild runs inside the package folder, so the output path must be absolute.
OUT="$(cd "$OUT" && pwd)"
if [ -e "$OUT/result.xcresult" ]; then
    echo "$OUT already has a result bundle. xcodebuild refuses to overwrite it. Pick another --out."
    exit 2
fi

# The outline PDFs are generated on the host before Xcode copies test resources.
if [ "$TARGET" = "MEGAPDFViewerBenchmarks" ]; then
    FIXTURES="$PACKAGE/Tests/$TARGET/OutlineFixtures"
    mkdir -p "$FIXTURES"
    swiftc "$ROOT"/scripts/benchmark-fixtures/pdf-outline/*.swift -o "$OUT/pdf-outline-fixture-gen" || exit 2
    "$OUT/pdf-outline-fixture-gen" "$FIXTURES" || exit 2
fi

# Each skipped test is left out of the run. The report lists it with its reason.
SKIP_ARGS=()
if [ -n "$SKIPPED" ]; then
    SKIPPED_TESTS="$(python3 "$ROOT/scripts/benchmark_ci.py" skipped "$SKIPPED")" || exit 2
    while IFS= read -r TEST; do
        [ -n "$TEST" ] && SKIP_ARGS+=(-skip-testing:"$TARGET/$TEST")
    done <<< "$SKIPPED_TESTS"
fi

# The configuration is always explicit: a scheme's own test configuration must not differ from the manifest.
# Release needs testability for @testable imports in the benchmarks.
EXTRA=(-configuration "$CONFIGURATION")
[ "$CONFIGURATION" = "Release" ] && EXTRA+=(ENABLE_TESTABILITY=YES)

# The manifest tells a later --base compare which configuration, Xcode and machine made the numbers.
XCODE="$(xcodebuild -version 2>&1 | tr '\n' ' ' | sed 's/ *$//')"
HOST="$(sysctl -n hw.model 2>&1)"
CPU="$(sysctl -n machdep.cpu.brand_string 2>&1)"
COMMIT="$(git -C "$ROOT" rev-parse HEAD 2>&1)"
printf '{\n  "configuration": "%s",\n  "xcode": "%s",\n  "host": "%s",\n  "cpu": "%s",\n  "simulator": "%s",\n  "commit": "%s",\n  "package": "%s",\n  "target": "%s",\n  "only": "%s"\n}\n' \
    "$CONFIGURATION" "$XCODE" "$HOST" "$CPU" "$SIM" "$COMMIT" "$NAME" "$TARGET" "$ONLY" > "$OUT/manifest.json"

# TEST_RUNNER_ variables reach the test process without the prefix. BenchmarkCase skips its tests without it.
export TEST_RUNNER_MEGA_BENCH=1
echo "== $TARGET on simulator $SIM ($CONFIGURATION) =="
# One test at a time, no coverage and no sanitizers: all of them change the numbers, and a custom scheme may turn them on.
# The -enable...Sanitizer flags alone still compile with a scheme's sanitizer, so the build settings are set too.
# A scheme's test plan can still retry or repeat a test. The reporter rejects a test that ran more than once.
(cd "$PACKAGE" && xcodebuild test \
    -scheme "$SCHEME" \
    -only-testing:"$TARGET${ONLY:+/$ONLY}" \
    -destination "platform=iOS Simulator,id=$SIM" \
    -derivedDataPath "$ROOT/derivedData/benchmarks/build" \
    -resultBundlePath "$OUT/result.xcresult" \
    -parallel-testing-enabled NO \
    -enableCodeCoverage NO \
    -enableAddressSanitizer NO \
    -enableThreadSanitizer NO \
    -enableUndefinedBehaviorSanitizer NO \
    -collect-test-diagnostics never \
    -skipPackagePluginValidation \
    ENABLE_ADDRESS_SANITIZER=NO ENABLE_THREAD_SANITIZER=NO ENABLE_UNDEFINED_BEHAVIOR_SANITIZER=NO \
    SWIFT_SUPPRESS_WARNINGS=NO "${EXTRA[@]}" ${SKIP_ARGS[@]+"${SKIP_ARGS[@]}"}) > "$OUT/xcodebuild.log" 2>&1
BUILD_STATUS=$?
if [ $BUILD_STATUS -ne 0 ]; then
    grep -E "error:|failed \(" "$OUT/xcodebuild.log" | head -20
    echo "xcodebuild exit $BUILD_STATUS (see $OUT/xcodebuild.log)"
fi

REPORT_ARGS=("$OUT/result.xcresult" --json "$OUT/metrics.json")
# A failed xcodebuild must not change the limits file, even when the selected tests have numbers.
if [ $WRITE_LIMITS -eq 1 ] && [ $BUILD_STATUS -eq 0 ]; then
    REPORT_ARGS+=(--write-limits "$LIMITS")
elif [ $WRITE_LIMITS -eq 1 ]; then
    echo "Limits file not written: xcodebuild failed"
fi
[ -n "$LIMITS" ] && REPORT_ARGS+=(--limits "$LIMITS")
[ -n "$ONLY" ] && REPORT_ARGS+=(--only "$ONLY")
[ -n "$SKIPPED" ] && REPORT_ARGS+=(--skipped "$SKIPPED")
[ -n "$BASE" ] && REPORT_ARGS+=(--base "$BASE")
[ -n "$MAX_REGRESSION" ] && REPORT_ARGS+=(--max-regression "$MAX_REGRESSION")
python3 "$ROOT/scripts/benchmark_report.py" "${REPORT_ARGS[@]}" | tee "$OUT/report.md"
REPORT_STATUS=${PIPESTATUS[0]}

echo "Output: $OUT"
[ $BUILD_STATUS -eq 0 ] && [ "$REPORT_STATUS" -eq 0 ]
