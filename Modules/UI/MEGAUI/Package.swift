// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MEGAUI",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAUI",
            targets: ["MEGAUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGAUI",
            dependencies: ["MEGADesignToken"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGAUITests",
            dependencies: ["MEGAUI"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ]
)
