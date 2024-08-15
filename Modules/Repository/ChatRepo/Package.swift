// swift-tools-version: 5.10

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
        .package(path: "../../Repository/MEGASDKRepo")
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
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ],
            swiftSettings: settings
        )
    ]
)
