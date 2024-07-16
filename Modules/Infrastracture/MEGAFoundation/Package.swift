// swift-tools-version: 5.9

import PackageDescription

let settings: [SwiftSetting] = [.enableExperimentalFeature("ExistentialAny"), .enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "MEGAFoundation",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAFoundation",
            targets: ["MEGAFoundation"])
    ],
    dependencies: [
        .package(path: "../MEGASwift"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "MEGAFoundation",
            dependencies: ["MEGASwift"],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAFoundationTests",
            dependencies: [
                "MEGAFoundation",
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras")
            ],
            swiftSettings: settings)
    ]
)
