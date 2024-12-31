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
        .package(path: "../../DataSource/MEGAChatSdk"),
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Repository/MEGASDKRepo"),
        .package(path: "../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "ChatRepo",
            dependencies: [
                "MEGADomain",
                "MEGAChatSdk",
                "MEGASDKRepo"
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
                .product(name: "MEGASDKRepoMock", package: "MEGASDKRepo")
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
