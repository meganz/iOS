// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "Video",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "Video",
            targets: ["Video"]
        ),
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGASwiftUI"),
    ],
    targets: [
        .target(
            name: "Video",
            dependencies: [
                "MEGASwiftUI"
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "VideoTests",
            dependencies: ["Video"],
            swiftSettings: settings
        ),
    ]
)
