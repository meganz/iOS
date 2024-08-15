// swift-tools-version: 5.9

import PackageDescription

let settings: [SwiftSetting] = [.enableExperimentalFeature("ExistentialAny"), .enableExperimentalFeature("StrictConcurrency=targeted")]

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
        .package(path: "../../../Infrastracture/MEGATest"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main")
    ],
    targets: [
        .target(
            name: "PhotosBrowser",
            dependencies: ["MEGADomain",
                           "MEGAAssets",
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
