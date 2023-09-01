// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "MEGAPickerFileProviderRepo",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAPickerFileProviderRepo",
            targets: ["MEGAPickerFileProviderRepo"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/MEGAPickerFileProviderDomain"),
        .package(path: "../MEGASDKRepo"),
        .package(url: "https://github.com/meganz/SAMKeychain.git", from: "2.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "9.0.0")
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
    ]
)
