#!/bin/bash

vcpkg_baseline=ef7dbf94b9198bc58f45951adcf1f041fcbc5ea0
# Formating
green="\033[32m"
bold="\033[0m${green}\033[1m"
normal="\033[0m"

configure_vcpgk() {
  echo "${bold}Configuring vcpkg${normal}"
  if [ ! -d "vcpkg" ]; then
  echo "${bold}Clonning vcpkg${normal}"
    git clone https://github.com/microsoft/vcpkg.git
  fi
  cd vcpkg
  git checkout ${vcpkg_baseline}
  ./bootstrap-vcpkg.sh --disableMetrics
  cd ..
}

build_libs() {
  echo "${bold}Building libraries for device${normal}"
  cmake --preset mega-ios -DCMAKE_BUILD_TYPE=RelWithDebInfo -DVCPKG_ROOT=vcpkg -DCMAKE_VERBOSE_MAKEFILE=ON -DENABLE_MEDIA_FILE_METADATA=OFF \
  -S ../Modules/DataSource/MEGASDK/Sources/MEGASDK -B BUILD_ARM64_iOS
  
  echo "${bold}Building libraries for simulator${normal}"
  cmake --preset mega-ios -DCMAKE_BUILD_TYPE=RelWithDebInfo -DVCPKG_ROOT=vcpkg -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DENABLE_MEDIA_FILE_METADATA=OFF -S ../Modules/DataSource/MEGASDK/Sources/MEGASDK  -B BUILD_ARM64_simulator
}

merge_libraries() {
  echo "${bold}Merge libraries for arm64 iOS and iOS Simulator${normal}"

  mkdir -p arm64-ios-simulator-mega || true
  
  libtool -static -o arm64-ios-simulator-mega/libmegasdk.a \
    BUILD_ARM64_simulator/vcpkg_installed/arm64-ios-simulator-mega/lib/*.a
  
  mkdir -p arm64-ios-mega || true
  
  libtool -static -o arm64-ios-mega/libmegasdk.a \
    BUILD_ARM64_iOS/vcpkg_installed/arm64-ios-mega/lib/*.a
}

create_XCFramework() {
  rm -rf xcframework/libmegasdk.xcframework
  mkdir -p xcframework || true
  
  echo "${bold}Creating xcframework ${normal}"
  
  xcodebuild -create-xcframework \
    -library "arm64-ios-simulator-mega/libmegasdk.a" \
    -headers "BUILD_ARM64_simulator/vcpkg_installed/arm64-ios-simulator-mega/include" \
    -library "arm64-ios-mega/libmegasdk.a" \
    -headers "BUILD_ARM64_iOS/vcpkg_installed/arm64-ios-mega/include" \
    -output "xcframework/libmegasdk.xcframework"
}

main() {
  configure_vcpgk
  build_libs
  merge_libraries
  create_XCFramework
}

main


