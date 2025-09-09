// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency=targeted")
]

let package = Package(
    name: "MEGAPhotos",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGAPhotos",
            targets: ["MEGAPhotos"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGASwiftUI"),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main"),
        .package(path: "../../../Infrastructure/MEGASwift"),
        .package(path: "../../Infrastracture/MEGATest"),
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../MEGAAppPresentation"),
        .package(path: "../../../Presentation/MEGAL10n"),
        .package(path: "../../../Presentation/MEGAAssets"),
        .package(path: "../Shared/ContentLibraries"),
        .package(path: "../../../UI/MEGAUIComponent")
    ],
    targets: [
        .target(
            name: "MEGAPhotos",
            dependencies: [
                "MEGASwiftUI",
                "MEGADesignToken",
                "MEGADomain",
                "MEGAAppPresentation",
                "MEGASwift",
                "MEGAL10n",
                "MEGAAssets",
                "ContentLibraries",
                "MEGAUIComponent"
            ],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAPhotosTests",
            dependencies: [
                "MEGAPhotos",
                "MEGATest",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation")
            ],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
