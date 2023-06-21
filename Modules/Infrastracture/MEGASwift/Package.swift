// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MEGASwift",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGASwift",
            targets: ["MEGASwift"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGASwift",
            dependencies: [],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGASwiftTests",
            dependencies: ["MEGASwift"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ]
)
