// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "PhotosBrowser",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PhotosBrowser",
            targets: ["PhotosBrowser"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../MEGASharedRepo/MEGATest"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "PhotosBrowser",
            dependencies: ["MEGADomain",
                           "MEGAAssets",
                           "MEGAL10n",
                           "MEGAAppPresentation",
                           "MEGASwiftUI",
                           "MEGADesignToken"],
            swiftSettings: settings),
        .testTarget(
            name: "PhotosBrowserTests",
            dependencies: ["PhotosBrowser",
                           "MEGAAppPresentation",
                           "MEGAAssets",
                           "MEGATest",
                           .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation")],
            swiftSettings: settings)
    ]
)
