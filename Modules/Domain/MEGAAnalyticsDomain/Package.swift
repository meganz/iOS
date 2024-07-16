// swift-tools-version: 5.9

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny"), .enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "MEGAAnalyticsDomain",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAAnalyticsDomain",
            targets: ["MEGAAnalyticsDomain"]),
        .library(
            name: "MEGAAnalyticsDomainMock",
            targets: ["MEGAAnalyticsDomainMock"])
    ],
    dependencies: [
        .package(path: "../MEGADomain"),
        .package(path: "../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "MEGAAnalyticsDomain",
            dependencies: ["MEGADomain"],
            swiftSettings: settings
        ),
        .target(
            name: "MEGAAnalyticsDomainMock",
            dependencies: ["MEGAAnalyticsDomain"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAAnalyticsDomainTests",
            dependencies: [
                "MEGAAnalyticsDomain",
                "MEGAAnalyticsDomainMock",
                "MEGATest"
            ],
            swiftSettings: settings
        )
    ]
)
