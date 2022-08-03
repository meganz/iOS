// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MEGAFoundation",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(
            name: "MEGAFoundation",
            targets: ["MEGAFoundation"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGAFoundation",
            dependencies: []),
        .testTarget(
            name: "MEGAFoundationTests",
            dependencies: ["MEGAFoundation"]),
    ]
)
