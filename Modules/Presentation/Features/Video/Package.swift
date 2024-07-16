// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let settings: [SwiftSetting] = [.enableExperimentalFeature("ExistentialAny"), .enableExperimentalFeature("StrictConcurrency=targeted")]

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
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../../Presentation/MEGAAssets"),
        .package(path: "../../../Presentation/MEGAL10n"),
        .package(path: "../../../Presentation/MEGAPresentation"),
        .package(path: "../../Infrastracture/MEGATest"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Video",
            dependencies: [
                "MEGASwiftUI",
                "MEGAAssets",
                "MEGAL10n",
                "MEGAPresentation",
                .product(
                    name: "AsyncAlgorithms",
                    package: "swift-async-algorithms"
                )
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "VideoTests",
            dependencies: [
                "Video",
                "MEGADomain",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                "MEGATest"
            ],
            swiftSettings: settings
        )
    ]
)
