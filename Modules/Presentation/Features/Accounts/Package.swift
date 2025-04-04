// swift-tools-version: 6.0

import PackageDescription

private let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "Accounts",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
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
        .package(path: "../../../Localization/MEGAL10n"),
        .package(path: "../../MEGAAppPresentation"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../../Infrastracture/MEGATest"),
        .package(path: "../../../MEGAAssets"),
        .package(path: "../MEGAUI"),
        .package(path: "../Settings"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.10.0")
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
                           "Settings"],
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
                           .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation"),
                           .product(name: "MEGADomainMock", package: "MEGADomain"),
                           .product(name: "MEGAAppSDKRepoMock", package: "MEGAAppSDKRepo"),
                           .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
