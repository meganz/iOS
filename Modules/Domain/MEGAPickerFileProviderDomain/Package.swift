// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "MEGAPickerFileProviderDomain",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAPickerFileProviderDomain",
            targets: ["MEGAPickerFileProviderDomain"]
        )
    ],
    dependencies: [
        .package(path: "../MEGADomain")
    ],
    targets: [
        .target(
            name: "MEGAPickerFileProviderDomain",
            dependencies: ["MEGADomain"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAPickerFileProviderDomainTests",
            dependencies: ["MEGAPickerFileProviderDomain"],
            swiftSettings: settings
        )
    ]
)
