// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "Video",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "Video",
            targets: ["Video"]
        )
    ],
    dependencies: [
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../../UI/MEGAUIKit"),
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../../Presentation/MEGAAssets"),
        .package(path: "../../../Presentation/MEGAL10n"),
        .package(path: "../../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Infrastracture/MEGATest"),
        .package(path: "../Shared/ContentLibraries"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Video",
            dependencies: [
                "MEGASwiftUI",
                "MEGAUIKit",
                "MEGAAssets",
                "MEGAL10n",
                "MEGAAppPresentation",
                "ContentLibraries",
                .product(
                    name: "AsyncAlgorithms",
                    package: "swift-async-algorithms"
                )
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "VideoTests",
            dependencies: [
                "Video",
                "MEGADomain",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                "MEGATest",
                .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation")
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
