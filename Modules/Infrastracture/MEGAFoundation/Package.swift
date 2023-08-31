// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "MEGAFoundation",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAFoundation",
            targets: ["MEGAFoundation"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGAFoundation",
            dependencies: [],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAFoundationTests",
            dependencies: ["MEGAFoundation"],
            swiftSettings: settings)
    ]
)
