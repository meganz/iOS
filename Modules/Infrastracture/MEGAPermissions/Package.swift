// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [.enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "MEGAPermissions",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAPermissions",
            targets: ["MEGAPermissions"]
        ),
        .library(
            name: "MEGAPermissionsMock",
            targets: ["MEGAPermissionsMock"]
        )
    ],
    dependencies: [
        .package(path: "../../MEGASharedRepo/MEGASwift")
    ],
    targets: [
        .target(
            name: "MEGAPermissions",
            dependencies: [],
            swiftSettings: settings
        ),
        .target(
            name: "MEGAPermissionsMock",
            dependencies: ["MEGAPermissions"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAPermissionsTests",
            dependencies: [
                "MEGAPermissions",
                "MEGAPermissionsMock",
                "MEGASwift"
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
