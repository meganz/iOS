#!/bin/sh

rm -rf .tmp/ || true

URL="https://download.videolan.org/pub/cocoapods/prod/MobileVLCKit-3.6.0-c73b779f-dd8bfdba.tar.xz"

mkdir .tmp/

curl -L -o .tmp/MobileVLCKit.tar.xz "$URL"
tar -xf .tmp/MobileVLCKit.tar.xz -C .tmp/

LOCATION=".tmp/MobileVLCKit-binary/MobileVLCKit.xcframework"

xcodebuild -create-xcframework \
    -framework "$LOCATION/ios-arm64_i386_x86_64-simulator/MobileVLCKit.framework" \
    -debug-symbols "${PWD}/$LOCATION/ios-arm64_i386_x86_64-simulator/dSYMs/MobileVLCKit.framework.dSYM" \
    -framework "$LOCATION/ios-arm64_armv7_armv7s/MobileVLCKit.framework" \
    -debug-symbols "${PWD}/$LOCATION/ios-arm64_armv7_armv7s/dSYMs/MobileVLCKit.framework.dSYM" \
    -output .tmp/VLCKit.xcframework

ditto -c -k --sequesterRsrc --keepParent ".tmp/VLCKit.xcframework" ".tmp/VLCKit.xcframework.zip"
