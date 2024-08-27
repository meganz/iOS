// swift-tools-version: 5.10

import PackageDescription

let settings: [SwiftSetting] = [.enableExperimentalFeature("ExistentialAny"), .enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "MEGAPhotos",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAPhotos",
            targets: ["MEGAPhotos"]),
    ],
    targets: [
        .target(
            name: "MEGAPhotos",
            swiftSettings: settings),
        .testTarget(
            name: "MEGAPhotosTests",
            dependencies: ["MEGAPhotos"],
            swiftSettings: settings),
    ]
)
