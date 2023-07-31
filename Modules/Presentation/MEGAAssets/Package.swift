// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MEGAAssets",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAAssets",
            targets: ["MEGAAssets"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MEGAAssets",
            dependencies: [],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGAAssetsTests",
            dependencies: ["MEGAAssets"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ]
)
