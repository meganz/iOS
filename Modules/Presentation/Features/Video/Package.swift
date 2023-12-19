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
        )
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGASwiftUI"),
        .package(path: "../../../Presentation/MEGAAssets"),
        .package(path: "../../../Presentation/MEGAL10n")
    ],
    targets: [
        .target(
            name: "Video",
            dependencies: [
                "MEGASwiftUI",
                "MEGAAssets",
                "MEGAL10n"
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "VideoTests",
            dependencies: ["Video"],
            swiftSettings: settings
        )
    ]
)
