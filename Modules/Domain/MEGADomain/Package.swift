// swift-tools-version: 5.9

import PackageDescription

let settings: [SwiftSetting] = [.enableExperimentalFeature("ExistentialAny"), .enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "MEGADomain",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGADomain",
            targets: ["MEGADomain"]),
        .library(
            name: "MEGADomainMock",
            targets: ["MEGADomainMock"])
    ],
    dependencies: [
        .package(path: "../../Infrastracture/MEGASwift"),
        .package(path: "../../Infrastracture/MEGAFoundation"),
        .package(path: "../../Infrastracture/MEGATest"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MEGADomain",
            dependencies: ["MEGASwift",
                           "MEGAFoundation",
                           .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: settings),
        .target(
            name: "MEGADomainMock",
            dependencies: ["MEGADomain"],
            swiftSettings: settings),
        .testTarget(
            name: "MEGADomainTests",
            dependencies: ["MEGADomain", "MEGADomainMock", "MEGATest"],
            swiftSettings: settings)
    ]
)
