// swift-tools-version: 5.10
import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency=targeted")
]

let package = Package(
    name: "LogRepo",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "LogRepo",
            targets: ["LogRepo"]),
    ],
    dependencies: [
        .package(path: "../../DataSource/MEGAChatSdk"),
        .package(path: "../../Domain/MEGADomain"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "LogRepo",
            dependencies: [
                "MEGAChatSdk",
                "MEGADomain",
                "CocoaLumberjack",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
            ],
            swiftSettings: settings
        )
    ]
)
