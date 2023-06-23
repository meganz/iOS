// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MEGATest",
    products: [
        .library(
            name: "MEGATest",
            targets: ["MEGATest"])
    ],
    targets: [
        .target(
            name: "MEGATest",
            dependencies: [],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        )
    ]
)
