// swift-tools-version: 5.10

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency=targeted")
]

let package = Package(
    name: "PhotosBrowser",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "PhotosBrowser",
            targets: ["PhotosBrowser"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../MEGAPresentation"),
        .package(path: "../../../Presentation/MEGAAssets"),
        .package(path: "../../../Presentation/MEGAL10n"),
        .package(path: "../../../Infrastracture/MEGATest"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main")
    ],
    targets: [
        .target(
            name: "PhotosBrowser",
            dependencies: ["MEGADomain",
                           "MEGAAssets",
                           "MEGAL10n",
                           "MEGAPresentation",
                           "MEGASwiftUI",
                           "MEGADesignToken"],
            swiftSettings: settings),
        .testTarget(
            name: "PhotosBrowserTests",
            dependencies: ["PhotosBrowser",
                           "MEGAPresentation",
                           "MEGAAssets",
                           "MEGATest",
                           .product(name: "MEGAPresentationMock", package: "MEGAPresentation")],
            swiftSettings: settings)
    ]
)
