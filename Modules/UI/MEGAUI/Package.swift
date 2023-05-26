// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MEGAUI",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAUI",
            targets: ["MEGAUI"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGAUI",
            dependencies: []),
        .testTarget(
            name: "MEGAUITests",
            dependencies: ["MEGAUI"])
    ]
)
