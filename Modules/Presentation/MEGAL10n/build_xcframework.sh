#!/bin/bash
set -e

# Framework name as a variable
FRAMEWORK_NAME="MEGAL10n"

# This shell script will generate $FRAMEWORK_NAME xcframework

# Go to the $FRAMEWORK_NAME project root
echo "📂 Going to the $FRAMEWORK_NAME project root..."
cd Framework/$FRAMEWORK_NAME

# Cleanup output directories
echo "🧹 Cleaning up output directories..."
rm -rf output

# Archive for iOS
echo "📦 Archiving for iOS..."
xcodebuild archive \
    -project $FRAMEWORK_NAME.xcodeproj \
    -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS" \
    -archivePath "output/archives/$FRAMEWORK_NAME-iOS" \
    -quiet

# Archive for iOS Simulator
echo "📦 Archiving for iOS Simulator..."
xcodebuild archive \
    -project $FRAMEWORK_NAME.xcodeproj \
    -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "output/archives/$FRAMEWORK_NAME-iOS_Simulator" \
    -quiet

# Create $FRAMEWORK_NAME.xcframework using output archives
echo "🛠️ Creating $FRAMEWORK_NAME.xcframework using output archives..."
xcodebuild -create-xcframework \
    -archive output/archives/$FRAMEWORK_NAME-iOS.xcarchive -framework $FRAMEWORK_NAME.framework \
    -archive output/archives/$FRAMEWORK_NAME-iOS_Simulator.xcarchive -framework $FRAMEWORK_NAME.framework \
    -output output/xcframeworks/$FRAMEWORK_NAME.xcframework \

rm -rf xcframeworks/*
mv output/xcframeworks/$FRAMEWORK_NAME.xcframework xcframeworks/

# Cleanup output directories
echo "🧹 Cleaning up output directories..."
rm -rf output

echo "🎉 ✅ Done: $FRAMEWORK_NAME.xcframework has been successfully created!"