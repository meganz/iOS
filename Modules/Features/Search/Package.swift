// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "Search",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "Search",
            targets: ["Search"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Search",
            dependencies: []),
        .testTarget(
            name: "SearchTests",
            dependencies: ["Search"]),
    ]
)
