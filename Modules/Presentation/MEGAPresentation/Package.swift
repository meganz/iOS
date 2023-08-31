// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "MEGAPresentation",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAPresentation",
            targets: ["MEGAPresentation"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Domain/MEGAAnalyticsDomain"),
        .package(path: "../../Repository/MEGASDKRepo"),
        .package(path: "../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "MEGAPresentation",
            dependencies: [
                "MEGAAnalyticsDomain",
                "MEGADomain",
                "MEGASDKRepo"
            ],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAPresentationTests",
            dependencies: ["MEGAPresentation",
                           "MEGATest",
                           .product(name: "MEGADomainMock", package: "MEGADomain")],
            swiftSettings: settings)
    ]
)
