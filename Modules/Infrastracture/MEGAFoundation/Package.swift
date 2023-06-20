// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MEGAFoundation",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAFoundation",
            targets: ["MEGAFoundation"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGAFoundation",
            dependencies: [],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGAFoundationTests",
            dependencies: ["MEGAFoundation"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ]
)
