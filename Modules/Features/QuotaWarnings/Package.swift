// swift-tools-version: 6.0

import PackageDescription

private let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "QuotaWarnings",
    platforms: [
        .macOS(.v12), .iOS(.v17)
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
        .package(path: "../../Repository/MEGARepo"),
        .package(path: "../../MEGASharedRepo/MEGAUIComponent"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../MEGASharedRepo/MEGAInfrastructure"),
        .package(path: "../../MEGASharedRepo/MEGAPreference"),
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main")
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
                           "MEGARepo",
                           "MEGAUIComponent",
                           "MEGASwift",
                           "MEGAInfrastructure",
                           "MEGAPreference",
                           .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")],
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
                           .product(name: "MEGADomainMock", package: "MEGADomain"),
                           "MEGASwift",
                           "MEGAUIComponent",
                           "MEGAInfrastructure",
                           "MEGAL10n",
                           .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios"),
                           .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation"),
                           .product(name: "MEGAPreferenceMocks", package: "MEGAPreference")],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
