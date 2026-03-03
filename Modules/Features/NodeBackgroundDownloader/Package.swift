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
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main")
    ],
    targets: [
        .target(
            name: "NodeBackgroundDownloader",
            dependencies: [
                "MEGADomain",
                "MEGARepo",
                "MEGAL10n",
                "MEGAAppSDKRepo",
                "MEGAAppPresentation",
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")
            ],
            swiftSettings: settings),
        .testTarget(
            name: "NodeBackgroundDownloaderTests",
            dependencies: [
                "NodeBackgroundDownloader",
                .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation")
            ],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
