// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

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
    ],
    swiftLanguageModes: [.v6]
)
