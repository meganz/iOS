// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]),
                                .enableExperimentalFeature("ExistentialAny"),
                                .enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "ChatRepo",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "ChatRepo",
            targets: ["ChatRepo"]),
        .library(
            name: "ChatRepoMock",
            targets: ["ChatRepoMock"])
    ],
    dependencies: [
        .package(path: "../../DataSource/MEGASdk"),
        .package(path: "../../DataSource/MEGAChatSdk"),
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "ChatRepo",
            dependencies: [
                "MEGADomain",
                "MEGAChatSdk",
                "MEGASdk",
                "MEGAAppSDKRepo"
            ],
            cxxSettings: [
                .define("ENABLE_CHAT")
            ],
            swiftSettings: settings
        ),
        .target(
            name: "ChatRepoMock",
            dependencies: ["ChatRepo"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "ChatRepoTests",
            dependencies: [
                "ChatRepo",
                "ChatRepoMock",
                "MEGATest",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                .product(name: "MEGAAppSDKRepoMock", package: "MEGAAppSDKRepo")
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
