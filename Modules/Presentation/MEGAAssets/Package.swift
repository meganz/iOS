// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAAssets",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAAssets",
            targets: ["MEGAAssets"])
    ],
    dependencies: [
        .package(path: "../../../Infrastructure/MEGASwift")
    ],
    targets: [
        .target(
            name: "MEGAAssets",
            dependencies: [
                "MEGASwift"
            ],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAAssetsTests",
            dependencies: ["MEGAAssets"],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
