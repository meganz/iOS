// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAFoundation",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGAFoundation",
            targets: ["MEGAFoundation"])
    ],
    dependencies: [
        .package(path: "../../MEGASharedRepo/MEGASwift")
    ],
    targets: [
        .target(
            name: "MEGAFoundation",
            dependencies: ["MEGASwift"],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAFoundationTests",
            dependencies: [
                "MEGAFoundation"
            ],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
