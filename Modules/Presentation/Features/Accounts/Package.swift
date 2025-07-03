// swift-tools-version: 6.0

import PackageDescription

private let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "Accounts",
    platforms: [
        .macOS(.v10_15), .iOS(.v16)
    ],
    products: [
        .library(
            name: "Accounts",
            targets: ["Accounts"]),
        .library(
            name: "AccountsMock",
            targets: ["AccountsMock"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../MEGAL10n"),
        .package(path: "../../MEGAAppPresentation"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../../MEGASharedRepo/MEGATest"),
        .package(path: "../../../Presentation/MEGAAssets"),
        .package(path: "../../../UI/MEGAUI"),
        .package(path: "../Settings"),
        .package(path: "../../../MEGASharedRepo/MEGAUIComponent"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "12.6.0"),
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main"),
        .package(path: "../../../MEGASharedRepo/MEGASwift")
    ],
    targets: [
        .target(
            name: "Accounts",
            dependencies: ["MEGADomain",
                           "MEGAL10n",
                           "MEGAAppPresentation",
                           "MEGASwiftUI",
                           "MEGAAssets",
                           "MEGAUI",
                           "Settings",
                           "MEGAUIComponent"],
            swiftSettings: settings
        ),
        .target(
            name: "AccountsMock",
            dependencies: ["Accounts"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "AccountsTests",
            dependencies: ["Accounts",
                           "AccountsMock",
                           "MEGADomain",
                           "MEGAAppPresentation",
                           "MEGATest",
                           "MEGASwift",
                           .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation"),
                           .product(name: "MEGADomainMock", package: "MEGADomain"),
                           .product(name: "MEGAAppSDKRepoMock", package: "MEGAAppSDKRepo"),
                           .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                           .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
