#!/bin/bash
#
# Builds MEGA SDK and ChatSDK static libraries for iOS device and simulator,
# merges them, and packages them as XCFrameworks.
#
# Prerequisites: cmake, vcpkg, xcodebuild, libtool

set -euo pipefail

# --- Configuration ---

VCPKG_BASELINE="ef7dbf94b9198bc58f45951adcf1f041fcbc5ea0"
CORES=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CHATSDK_SRC="${REPO_ROOT}/Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK"
SDK_SRC="${REPO_ROOT}/Modules/DataSource/MEGASDK/Sources/MEGASDK"

BUILD_DIR_DEVICE="BUILD_ARM64_iOS"
BUILD_DIR_SIMULATOR="BUILD_ARM64_simulator"

VCPKG_DEVICE_LIB="${BUILD_DIR_DEVICE}/vcpkg_installed/arm64-ios-mega/lib"
VCPKG_SIMULATOR_LIB="${BUILD_DIR_SIMULATOR}/vcpkg_installed/arm64-ios-simulator-mega/lib"
VCPKG_DEVICE_INCLUDE="${BUILD_DIR_DEVICE}/vcpkg_installed/arm64-ios-mega/include"
VCPKG_SIMULATOR_INCLUDE="${BUILD_DIR_SIMULATOR}/vcpkg_installed/arm64-ios-simulator-mega/include"

MERGED_DEVICE_DIR="arm64-ios-mega"
MERGED_SIMULATOR_DIR="arm64-ios-simulator-mega"

# Formatting
GREEN="\033[32m"
BOLD="\033[0m${GREEN}\033[1m"
NORMAL="\033[0m"

# --- Cleanup trap ---

cleanup() {
  rm -rf temp_sdk_include temp_chat_include
}
trap cleanup EXIT

# --- Functions ---

configure_vcpkg() {
  echo -e "${BOLD}Configuring vcpkg${NORMAL}"
  if [ ! -d "vcpkg" ]; then
    echo -e "${BOLD}Cloning vcpkg${NORMAL}"
    git clone https://github.com/microsoft/vcpkg.git
  fi
  pushd vcpkg > /dev/null
  git checkout "${VCPKG_BASELINE}"
  ./bootstrap-vcpkg.sh --disableMetrics
  popd > /dev/null
}

build_libs() {
  echo -e "${BOLD}Building libraries for device${NORMAL}"
  cmake --preset mega-ios \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DVCPKG_ROOT=vcpkg \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -S "${CHATSDK_SRC}" \
    -DSDK_DIR="${SDK_SRC}" \
    -B "${BUILD_DIR_DEVICE}"
  cmake --build "${BUILD_DIR_DEVICE}" -j"${CORES}"

  echo -e "${BOLD}Building libraries for simulator${NORMAL}"
  cmake --preset mega-ios \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DVCPKG_ROOT=vcpkg \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -S "${CHATSDK_SRC}" \
    -DSDK_DIR="${SDK_SRC}" \
    -B "${BUILD_DIR_SIMULATOR}"
  cmake --build "${BUILD_DIR_SIMULATOR}" -j"${CORES}"
}

merge_libraries() {
  echo -e "${BOLD}Merging third party libraries for arm64 iOS and iOS Simulator${NORMAL}"

  mkdir -p "${MERGED_SIMULATOR_DIR}"

  # Remove symbolic links to webrtc to avoid libtool warning about duplicated symbols
  rm -f "${VCPKG_SIMULATOR_LIB}/libssl.a" "${VCPKG_SIMULATOR_LIB}/libcrypto.a"

  libtool -static -o "${MERGED_SIMULATOR_DIR}/libmegathirdparty.a" \
    "${VCPKG_SIMULATOR_LIB}"/*.a

  mkdir -p "${MERGED_DEVICE_DIR}"

  # Remove symbolic links to webrtc to avoid libtool warning about duplicated symbols
  rm -f "${VCPKG_DEVICE_LIB}/libssl.a" "${VCPKG_DEVICE_LIB}/libcrypto.a"

  libtool -static -o "${MERGED_DEVICE_DIR}/libmegathirdparty.a" \
    "${VCPKG_DEVICE_LIB}"/*.a

  echo -e "${BOLD}Merging ccronexpr library into SDK libraries for arm64 iOS and iOS Simulator${NORMAL}"

  libtool -static -o "${MERGED_DEVICE_DIR}/libSDKlib.a" \
    "${BUILD_DIR_DEVICE}/third-party/mega/libSDKlib.a" \
    "${BUILD_DIR_DEVICE}/third-party/mega/third_party/ccronexpr/libccronexpr.a"

  libtool -static -o "${MERGED_SIMULATOR_DIR}/libSDKlib.a" \
    "${BUILD_DIR_SIMULATOR}/third-party/mega/libSDKlib.a" \
    "${BUILD_DIR_SIMULATOR}/third-party/mega/third_party/ccronexpr/libccronexpr.a"
}

create_xcframeworks() {
  rm -rf xcframework
  mkdir -p xcframework

  echo -e "${BOLD}Creating xcframework for third party code${NORMAL}"

  xcodebuild -create-xcframework \
    -library "${MERGED_SIMULATOR_DIR}/libmegathirdparty.a" \
    -headers "${VCPKG_SIMULATOR_INCLUDE}" \
    -library "${MERGED_DEVICE_DIR}/libmegathirdparty.a" \
    -headers "${VCPKG_DEVICE_INCLUDE}" \
    -output "xcframework/libmegathirdparty.xcframework"

  echo -e "${BOLD}Creating xcframework for SDK${NORMAL}"

  mkdir -p temp_sdk_include
  cp "${SDK_SRC}/include/megaapi.h" temp_sdk_include

  xcodebuild -create-xcframework \
    -library "${MERGED_DEVICE_DIR}/libSDKlib.a" \
    -headers "temp_sdk_include" \
    -library "${MERGED_SIMULATOR_DIR}/libSDKlib.a" \
    -headers "temp_sdk_include" \
    -output "xcframework/libmegasdk.xcframework"

  rm -rf temp_sdk_include

  echo -e "${BOLD}Creating xcframework for MEGAChat${NORMAL}"

  mkdir -p temp_chat_include
  cp "${CHATSDK_SRC}/src/megachatapi.h" temp_chat_include

  xcodebuild -create-xcframework \
    -library "${BUILD_DIR_DEVICE}/src/libCHATlib.a" \
    -headers "temp_chat_include" \
    -library "${BUILD_DIR_SIMULATOR}/src/libCHATlib.a" \
    -headers "temp_chat_include" \
    -output "xcframework/libmegachatsdk.xcframework"

  rm -rf temp_chat_include
}

# --- Usage ---

usage() {
  echo "Usage: $(basename "$0") [--skip-build-libs]"
  echo "  --skip-build-libs  Skip the cmake build step (use existing build artifacts)"
  exit 1
}

# --- Parse arguments ---

SKIP_BUILD_LIBS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build-libs)
      SKIP_BUILD_LIBS=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# --- Main ---

main() {
  configure_vcpkg
  if [ "${SKIP_BUILD_LIBS}" = false ]; then
    build_libs
  else
    echo -e "${BOLD}Skipping build_libs step${NORMAL}"
  fi
  merge_libraries
  create_xcframeworks
}

main
