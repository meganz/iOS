// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency=targeted")
]

let package = Package(
    name: "Authentication",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "Authentication",
            targets: ["Authentication"])
    ],
    dependencies: [
        .package(path: "../../../MEGASharedRepo/MEGAAuthentication")
    ],
    targets: [
        .target(
            name: "Authentication",
            dependencies: [
                .product(name: "MEGAAuthenticationUIComponents", package: "MEGAAuthentication"),
                .product(name: "MEGAAuthenticationDomain", package: "MEGAAuthentication")
            ],
            swiftSettings: settings),
        .testTarget(
            name: "AuthenticationTests",
            dependencies: ["Authentication"],
            swiftSettings: settings
        )
    ]
)
