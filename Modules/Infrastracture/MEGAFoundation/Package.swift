// swift-tools-version: 5.9

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "MEGAFoundation",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAFoundation",
            targets: ["MEGAFoundation"])
    ],
    dependencies: [
        .package(path: "../MEGASwift")
    ],
    targets: [
        .target(
            name: "MEGAFoundation",
            dependencies: ["MEGASwift"],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAFoundationTests",
            dependencies: ["MEGAFoundation"],
            swiftSettings: settings)
    ]
)
