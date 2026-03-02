// swift-tools-version: 6.2

import PackageDescription

let settings: [SwiftSetting] = [
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "NodeBackgroundDownloader",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "NodeBackgroundDownloader",
            targets: ["NodeBackgroundDownloader"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../MEGASharedRepo/MEGARepo"),
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../Presentation/MEGAL10n")
    ],
    targets: [
        .target(
            name: "NodeBackgroundDownloader",
            dependencies: [
                "MEGADomain",
                "MEGARepo",
                "MEGAL10n",
                "MEGAAppSDKRepo"
            ],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
