// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

// Custom XCTMetric types for `XCTestCase.measure(metrics:)`. Only benchmark test targets depend on it.
let package = Package(
    name: "MEGABenchmark",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MEGABenchmark",
            targets: ["MEGABenchmark"]),
        .library(
            name: "MEGABenchmarkUI",
            targets: ["MEGABenchmarkUI"])
    ],
    targets: [
        .target(
            name: "MEGABenchmark",
            swiftSettings: settings),
        // Helpers for UI tests. Only UI test bundles of benchmark host apps depend on it.
        .target(
            name: "MEGABenchmarkUI",
            swiftSettings: settings),
        .testTarget(
            name: "MEGABenchmarkTests",
            dependencies: ["MEGABenchmark"],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
