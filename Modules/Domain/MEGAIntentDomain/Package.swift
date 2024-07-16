// swift-tools-version: 5.9

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny"), .enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "MEGAIntentDomain",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAIntentDomain",
            targets: ["MEGAIntentDomain"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain")
    ],
    targets: [
        .target(
            name: "MEGAIntentDomain",
            dependencies: ["MEGADomain"],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAIntentDomainTests",
            dependencies: ["MEGADomain", "MEGAIntentDomain"],
            swiftSettings: settings)
    ]
)
