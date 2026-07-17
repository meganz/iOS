// swift-tools-version: 6.0

import PackageDescription

private let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "QuotaWarnings",
    platforms: [
        .macOS(.v12), .iOS(.v16)
    ],
    products: [
        .library(
            name: "QuotaWarnings",
            targets: ["QuotaWarnings"]),
        .library(
            name: "QuotaWarningsMock",
            targets: ["QuotaWarningsMock"])
    ],
    dependencies: [
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../MEGASharedRepo/MEGAUIComponent"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../MEGASharedRepo/MEGAInfrastructure")
    ],
    targets: [
        .target(
            name: "QuotaWarnings",
            dependencies: ["MEGADesignToken",
                           "MEGASwiftUI",
                           "MEGAAssets",
                           "MEGAAppPresentation",
                           "MEGAL10n",
                           "MEGADomain",
                           "MEGAAppSDKRepo",
                           "MEGAUIComponent",
                           "MEGASwift",
                           "MEGAInfrastructure"],
            swiftSettings: settings
        ),
        .target(
            name: "QuotaWarningsMock",
            dependencies: ["QuotaWarnings"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "QuotaWarningsTests",
            dependencies: ["QuotaWarnings",
                           "QuotaWarningsMock",
                           "MEGADomain",
                           "MEGAUIComponent"],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
