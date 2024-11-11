// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

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
    ],
    swiftLanguageModes: [.v6]
)
