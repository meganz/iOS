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
            type: .dynamic,
            targets: ["MEGAAssets"])
    ],
    dependencies: [
        .package(path: "../../../Infrastructure/MEGASwift")
    ],
    targets: [
        .binaryTarget(
            name: "MEGAAssetsBundle",
            path: "Frameworks/MEGAAssetsBundle.xcframework"
        ),
        .target(
            name: "MEGAAssets",
            dependencies: [
                "MEGASwift",
                "MEGAAssetsBundle"
            ],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAAssetsTests",
            dependencies: ["MEGAAssets"],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
