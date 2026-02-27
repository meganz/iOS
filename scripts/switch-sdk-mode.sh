#!/bin/bash
#
# Switches MEGASDK and MEGAChatSDK SPM packages between dev and binary mode.
#
# In dev mode, Package.swift compiles the SDK from source.
# In binary mode, Package.swift uses prebuilt xcframeworks.
#
# Usage: ./switch-sdk-mode.sh <dev|binary|status>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DATASOURCE_DIR="${REPO_ROOT}/Modules/DataSource"
PACKAGES=("MEGASDK" "MEGAChatSDK")

# Formatting
GREEN="\033[32m"
BOLD="\033[0m${GREEN}\033[1m"
NORMAL="\033[0m"

usage() {
  echo "Usage: $0 <dev|binary|status>"
  echo ""
  echo "  dev     - Compile SDK from source"
  echo "  binary  - Use prebuilt xcframeworks"
  echo "  status  - Show current mode for each package"
  exit 1
}

check_status() {
  for pkg in "${PACKAGES[@]}"; do
    local current="${DATASOURCE_DIR}/${pkg}/Package.swift"
    local dev_file="${DATASOURCE_DIR}/${pkg}/Package.dev.swift"
    local binary_file="${DATASOURCE_DIR}/${pkg}/Package.binary.swift"

    if [ ! -f "${current}" ]; then
      echo -e "${BOLD}${pkg}${NORMAL}: Package.swift not found"
      continue
    fi

    if diff -q "${current}" "${dev_file}" > /dev/null 2>&1; then
      echo -e "${BOLD}${pkg}${NORMAL}: dev"
    elif diff -q "${current}" "${binary_file}" > /dev/null 2>&1; then
      echo -e "${BOLD}${pkg}${NORMAL}: binary"
    else
      echo -e "${BOLD}${pkg}${NORMAL}: unknown (Package.swift differs from both dev and binary)"
    fi
  done
}

if [ $# -ne 1 ]; then
  usage
fi

MODE="$1"

case "${MODE}" in
  dev|binary) ;;
  status)
    check_status
    exit 0
    ;;
  *)
    echo "Error: Unknown mode '${MODE}'" >&2
    usage
    ;;
esac

for pkg in "${PACKAGES[@]}"; do
  SOURCE_FILE="${DATASOURCE_DIR}/${pkg}/Package.${MODE}.swift"
  TARGET_FILE="${DATASOURCE_DIR}/${pkg}/Package.swift"

  if [ ! -f "${SOURCE_FILE}" ]; then
    echo "Error: ${SOURCE_FILE} not found" >&2
    exit 1
  fi

  cp "${SOURCE_FILE}" "${TARGET_FILE}"
  echo -e "${BOLD}${pkg}${NORMAL}: switched to ${MODE} mode"
done

echo -e "${BOLD}Done.${NORMAL} Both packages are now in ${MODE} mode."
