// swift-tools-version: 6.0

import PackageDescription

private let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "QuotaWarnings",
    platforms: [
        .macOS(.v10_15), .iOS(.v16)
    ],
    products: [
        .library(
            name: "QuotaWarnings",
            targets: ["QuotaWarnings"]),
        .library(
            name: "QuotaWarningsMock",
            targets: ["QuotaWarningsMock"])
    ],
    targets: [
        .target(
            name: "QuotaWarnings",
            swiftSettings: settings
        ),
        .target(
            name: "QuotaWarningsMock",
            dependencies: ["QuotaWarnings"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "QuotaWarningsTests",
            dependencies: ["QuotaWarnings",
                           "QuotaWarningsMock"],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
