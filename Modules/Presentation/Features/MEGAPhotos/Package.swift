// swift-tools-version: 5.10

import PackageDescription

let settings: [SwiftSetting] = [.enableExperimentalFeature("ExistentialAny"), .enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "MEGAPhotos",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAPhotos",
            targets: ["MEGAPhotos"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGASwiftUI"),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main"),
        .package(path: "../../Infrastracture/MEGATest"),
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../../Presentation/MEGAL10n"),
        .package(path: "../../../Presentation/MEGAAssets"),
        .package(path: "../../Repository/MEGARepo")
    ],
    targets: [
        .target(
            name: "MEGAPhotos",
            dependencies: [
                "MEGASwiftUI",
                "MEGADesignToken",
                "MEGADomain",
                "MEGAL10n",
                "MEGAAssets",
                "MEGARepo"
            ],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAPhotosTests",
            dependencies: [
                "MEGAPhotos",
                "MEGATest",
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ],
            swiftSettings: settings)
    ]
)
