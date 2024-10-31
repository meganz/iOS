// swift-tools-version: 5.10
// To get this to Swift 6, we need to resolve a similar issue as
// https://forums.swift.org/t/ongeometrychange-assertion-failed-block-was-expected-to-execute-on-queue/74827

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency=targeted")
]
let package = Package(
    name: "ContentLibraries",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "ContentLibraries",
            targets: ["ContentLibraries"])
    ],
    dependencies: [
        .package(path: "../../../../Domain/MEGASwiftUI"),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main"),
        .package(path: "../../../Infrastracture/MEGATest"),
        .package(path: "../../../MEGAPresentation"),
        .package(path: "../../../../Presentation/MEGAL10n"),
        .package(path: "../../../../Presentation/MEGAAssets"),
        .package(path: "../../../../Domain/MEGADomain"),
        .package(path: "../../../Repository/MEGARepo"),
        .package(path: "../../../Repository/MEGASDKRepo")
    ],
    targets: [
        .target(
            name: "ContentLibraries",
            dependencies: [
                "MEGAPresentation",
                "MEGASwiftUI",
                "MEGADesignToken",
                "MEGADomain",
                "MEGAL10n",
                "MEGAAssets",
                "MEGARepo",
                "MEGASDKRepo"
            ],
            swiftSettings: settings),
        .testTarget(
            name: "ContentLibrariesTests",
            dependencies: [
                "ContentLibraries",
                "MEGAPresentation",
                "MEGAAssets",
                "MEGATest",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                .product(name: "MEGAPresentationMock", package: "MEGAPresentation")
            ],
            swiftSettings: settings)
    ]
)
