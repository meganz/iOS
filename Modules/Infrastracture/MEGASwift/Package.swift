// swift-tools-version: 5.10

import PackageDescription

let settings: [SwiftSetting] = [
    .enableExperimentalFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency=targeted")
]

let package = Package(
    name: "MEGASwift",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGASwift",
            targets: ["MEGASwift"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGASwift",
            dependencies: [],
            swiftSettings: settings),
        .testTarget(
            name: "MEGASwiftTests",
            dependencies: ["MEGASwift"],
            swiftSettings: settings)
    ]
)
