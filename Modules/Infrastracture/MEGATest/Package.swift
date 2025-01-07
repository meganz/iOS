// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]),
                                .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "MEGATest",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGATest",
            targets: ["MEGATest"])
    ],
    dependencies: [
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGATest",
            dependencies: [
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
