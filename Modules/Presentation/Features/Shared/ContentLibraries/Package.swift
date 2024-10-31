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
        .package(path: "../../../Repository/MEGASDKRepo"),
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
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
                "MEGASDKRepo",
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
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
                .product(name: "MEGAPresentationMock", package: "MEGAPresentation"),
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: settings)
    ]
)
