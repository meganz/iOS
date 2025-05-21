#!/bin/bash

# This shell script will generate MEGAAssetsBundle xcframework

# Go to the MEGAAssetsBundle project root
echo "📂 Going to the MEGAAssetsBundle project root..."
cd ../../../MEGAFrameworks/MEGAAssetsBundle

# Cleanup output directories
echo "🧹 Cleaning up output directories..."
rm -rf output

# Archive for iOS
echo "📦 Archiving for iOS..."
xcodebuild archive \
	-project MEGAAssetsBundle.xcodeproj \
	-scheme MEGAAssetsBundle \
	-destination "generic/platform=iOS" \
	-archivePath "output/archives/MEGAAssetsBundle-iOS"

# Archive for iOS Simulator
echo "📦 Archiving for iOS Simulator..."
xcodebuild archive \
	-project MEGAAssetsBundle.xcodeproj \
	-scheme MEGAAssetsBundle \
	-destination "generic/platform=iOS Simulator" \
	-archivePath "output/archives/MEGAAssetsBundle-iOS_Simulator"

# Create MEGAAssetsBundle.xcframework using output archives
echo "🛠️ Creating MEGAAssetsBundle.xcframework using output archives..."
xcodebuild -create-xcframework \
	-archive output/archives/MEGAAssetsBundle-iOS.xcarchive -framework MEGAAssetsBundle.framework \
	-archive output/archives/MEGAAssetsBundle-iOS_Simulator.xcarchive -framework MEGAAssetsBundle.framework \
	-output output/xcframeworks/MEGAAssetsBundle.xcframework

# Move MEGAAssetsBundle.xcframework to MEGAAssets package
echo "📁 Moving xcframework to MEGAAssets package..."
rm -rf ../../Modules/Presentation/MEGAAssets/Frameworks/*
mv output/xcframeworks/MEGAAssetsBundle.xcframework ../../Modules/Presentation/MEGAAssets/Frameworks/

# Cleanup output directories
echo "🧹 Cleaning up output directories..."
rm -rf output

echo "🎉 ✅ Done: MEGAAssetsBundle.xcframework has been successfully created!"
