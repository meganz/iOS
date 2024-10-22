// swift-tools-version: 6.0

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
            targets: ["ContentLibraries"]),
    ],
    dependencies: [
        .package(path: "../../../../Domain/MEGASwiftUI"),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main"),
        .package(path: "../../../Infrastracture/MEGATest"),
        .package(path: "../../../../Presentation/MEGAL10n"),
        .package(path: "../../../../Presentation/MEGAAssets"),
        .package(path: "../../../../Domain/MEGADomain"),
        .package(path: "../../../Repository/MEGARepo")
    ],
    targets: [
        .target(
            name: "ContentLibraries",
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
            name: "ContentLibrariesTests",
            dependencies: [
                "ContentLibraries",
                "MEGATest",
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ],
            swiftSettings: settings)
    ]
)
