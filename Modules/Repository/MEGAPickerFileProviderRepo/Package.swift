// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAPickerFileProviderRepo",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAPickerFileProviderRepo",
            targets: ["MEGAPickerFileProviderRepo"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/MEGAPickerFileProviderDomain"),
        .package(path: "../MEGASDKRepo")
    ],
    targets: [
        .target(
            name: "MEGAPickerFileProviderRepo",
            dependencies: ["MEGAPickerFileProviderDomain", "MEGASDKRepo"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAPickerFileProviderRepoTests",
            dependencies: ["MEGAPickerFileProviderRepo"],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
