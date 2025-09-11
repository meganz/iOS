// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAUI",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAUI",
            targets: ["MEGAUI"]),
        .library(
            name: "MEGAUIMock",
            targets: ["MEGAUIMock"])
    ],
    dependencies: [
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGAUI",
            dependencies: ["MEGADesignToken"],
            swiftSettings: settings),
        .target(
            name: "MEGAUIMock",
            dependencies: ["MEGAUI"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAUITests",
            dependencies: ["MEGAUI"],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
