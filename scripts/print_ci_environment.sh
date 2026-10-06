#!/bin/bash
# Prints facts about this CI machine that the repository does not record.
# Each stage runs on its own agent, so each stage calls this first.
# Parallel stages mix their lines in the console, so every line starts with the stage name.
# It never fails the build: every value falls back to the command's error text.

facts() {
    echo "Agent: ${NODE_NAME:-unknown}"
    echo "macOS: $(sw_vers -productVersion 2>&1) ($(sw_vers -buildVersion 2>&1)), $(uname -m), $(sysctl -n hw.model 2>&1)"
    echo "CPU cores: $(sysctl -n hw.ncpu 2>&1). Memory: $(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 )) GB"
    echo "Free disk in workspace: $(df -h . 2>&1 | awk 'NR == 2 { print $4 }')"
    echo "Xcode: $(xcodebuild -version 2>&1 | tr '\n' ' ')at $(xcode-select -p 2>&1)"
    echo "iOS simulator SDK: $(xcrun --sdk iphonesimulator --show-sdk-version 2>&1)"
    xcrun simctl list runtimes 2>&1 | grep "^iOS" | sed 's/^/Installed runtime: /'
    echo "Ruby: $(ruby -v 2>&1)"
    echo "Time zone: $(date +%Z) ($(readlink /etc/localtime 2>&1 | sed 's|.*zoneinfo/||')). TZ: ${TZ:-unset}. LANG: ${LANG:-unset}"
}

facts | sed "s/^/[CI machine | ${STAGE_NAME:-unknown stage}] /"
exit 0
