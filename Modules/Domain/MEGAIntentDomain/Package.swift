// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

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
        .package(path: "../../MEGASharedRepo/MEGASwift")
    ],
    targets: [
        .target(
            name: "MEGAIntentDomain",
            dependencies: ["MEGASwift"],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAIntentDomainTests",
            dependencies: ["MEGAIntentDomain"],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
