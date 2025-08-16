// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MEGAVideoPlayer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGAVideoPlayer",
            targets: ["MEGAVideoPlayer"]
        ),
        .library(
            name: "MEGAVideoPlayerMock",
            targets: ["MEGAVideoPlayerMock"]
        )
    ],
    dependencies: [
        .package(path: "../../../DataSource/MEGASDK"),
        .package(path: "../../../MEGASharedRepo/MEGALogger"),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MEGAVideoPlayer",
            dependencies: [
                .product(name: "MEGASdk", package: "MEGASDK"),
                "MEGALogger",
                "MEGADesignToken",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
            ],
            resources: [
                .process("Resources")
            ],
            cxxSettings: [
                .define("HAVE_LIBUV")
            ]
        ),
        .target(
            name: "MEGAVideoPlayerMock",
            dependencies: ["MEGAVideoPlayer"]
        ),
        .testTarget(
            name: "MEGAVideoPlayerTests",
            dependencies: [
                "MEGAVideoPlayer",
                "MEGAVideoPlayerMock"
            ]
        ),
    ]
)
