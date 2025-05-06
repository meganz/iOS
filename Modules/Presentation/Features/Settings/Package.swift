// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "Settings",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "Settings",
            targets: ["Settings"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../MEGAAppPresentation"),
        .package(path: "../../../Infrastracture/MEGATest"),
        .package(path: "../../../Localization/MEGAL10n"),
        .package(path: "../../../Repository/ChatRepo"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../Repository/LogRepo"),
        .package(path: "../../../UI/MEGAUIComponent"),
        .package(path: "../../../MEGASharedRepo/MEGAConnectivity"),
        .package(path: "../../../MEGAAssets")
    ],
    targets: [
        .target(
            name: "Settings",
            dependencies: [
                "MEGADomain",
                "MEGAAppPresentation",
                "MEGAL10n",
                "ChatRepo",
                "LogRepo",
                "MEGASwiftUI",
                "MEGAUIComponent",
                "MEGAConnectivity",
                "MEGAAssets"
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings",
                           "MEGATest",
                           .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation"),
                           .product(name: "MEGADomainMock", package: "MEGADomain")])
    ],
    swiftLanguageModes: [.v6]
)
