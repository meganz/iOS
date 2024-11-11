// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
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
    ],
    swiftLanguageModes: [.v6]
)
