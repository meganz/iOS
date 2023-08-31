// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "MEGATest",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGATest",
            targets: ["MEGATest"])
    ],
    targets: [
        .target(
            name: "MEGATest",
            dependencies: [],
            swiftSettings: settings
        )
    ]
)
