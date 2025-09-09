// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAPickerFileProviderRepo",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGAPickerFileProviderRepo",
            targets: ["MEGAPickerFileProviderRepo"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/MEGAPickerFileProviderDomain"),
        .package(path: "../MEGAAppSDKRepo")
    ],
    targets: [
        .target(
            name: "MEGAPickerFileProviderRepo",
            dependencies: ["MEGAPickerFileProviderDomain", "MEGAAppSDKRepo"],
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
