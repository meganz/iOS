// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "Settings",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Settings",
            targets: ["Settings"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../MEGASharedRepo/MEGATest"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Repository/ChatRepo"),
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../Repository/LogRepo"),
        .package(path: "../../MEGASharedRepo/MEGAUIComponent"),
        .package(path: "../../MEGASharedRepo/MEGAConnectivity"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../MEGASharedRepo/MEGAPreference"),
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main")
    ],
    targets: [
        .target(
            name: "Settings",
            dependencies: [
                "MEGADomain",
                "MEGAAppPresentation",
                "MEGAL10n",
                "ChatRepo",
                "MEGAAppSDKRepo",
                "LogRepo",
                "MEGASwiftUI",
                "MEGAUIComponent",
                "MEGAConnectivity",
                "MEGAAssets",
                "MEGAPreference",
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings",
                           "MEGATest",
                           .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation"),
                           .product(name: "MEGADomainMock", package: "MEGADomain"),
                           .product(name: "MEGAPreferenceMocks", package: "MEGAPreference")])
    ],
    swiftLanguageModes: [.v6]
)
