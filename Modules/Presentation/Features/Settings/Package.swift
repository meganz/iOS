// swift-tools-version: 5.10

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency=targeted")
]

let package = Package(
    name: "Settings",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "Settings",
            targets: ["Settings"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../MEGAPresentation"),
        .package(path: "../../../Infrastracture/MEGATest"),
        .package(path: "../../../Localization/MEGAL10n"),
        .package(path: "../../../Repository/ChatRepo"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../Repository/LogRepo")
    ],
    targets: [
        .target(
            name: "Settings",
            dependencies: ["MEGADomain", "MEGAPresentation", "MEGAL10n", "ChatRepo", "LogRepo", "MEGASwiftUI"],
            swiftSettings: settings),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings",
                           "MEGATest",
                           .product(name: "MEGAPresentationMock", package: "MEGAPresentation"),
                           .product(name: "MEGADomainMock", package: "MEGADomain")])
    ]
)
