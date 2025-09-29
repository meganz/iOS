// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

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
        .package(path: "../../../Presentation/MEGAL10n"),
        .package(path: "../../../MEGASharedRepo/MEGALogger"),
        .package(path: "../../../MEGASharedRepo/MEGAUIComponent"),
        .package(path: "../../../Infrastracture/MEGAPermissions"),
        .package(path: "../../../MEGASharedRepo/MEGAPreference"),
        .package(path: "../../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../../Repository/MEGAAppSDKRepo"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MEGAVideoPlayer",
            dependencies: [
                .product(name: "MEGASdk", package: "MEGASDK"),
                "MEGAL10n",
                "MEGALogger",
                "MEGADesignToken",
                "MEGAUIComponent",
                "MEGAPermissions",
                "MEGAPreference",
                "MEGASwift",
                .product(name: "MEGAAppSDKRepo", package: "MEGAAppSDKRepo"),
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
            ],
            resources: [
                .process("Resources")
            ],
            cxxSettings: [
                .define("HAVE_LIBUV")
            ],
            swiftSettings: settings
        ),
        .target(
            name: "MEGAVideoPlayerMock",
            dependencies: [
                "MEGAVideoPlayer",
                "MEGASwift",
                .product(name: "MEGASdk", package: "MEGASDK")
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAVideoPlayerTests",
            dependencies: [
                "MEGAVideoPlayer",
                "MEGAVideoPlayerMock",
                .product(name: "MEGAPermissions", package: "MEGAPermissions"),
                .product(name: "MEGAPermissionsMock", package: "MEGAPermissions")
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
