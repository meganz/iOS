// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
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
        .package(path: "../../UI/MEGASwiftUI"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../MEGASharedRepo/MEGATest"),
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../Shared/ContentLibraries"),
        .package(path: "../../MEGASharedRepo/MEGAUIComponent")
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
