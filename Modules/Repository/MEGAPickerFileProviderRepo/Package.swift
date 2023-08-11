// swift-tools-version: 5.8

import PackageDescription

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
        .package(path: "../../Domain/MEGAPickerFileProviderDomain")
    ],
    targets: [
        .target(
            name: "MEGAPickerFileProviderRepo",
            dependencies: ["MEGAPickerFileProviderDomain"]
        ),
        .testTarget(
            name: "MEGAPickerFileProviderRepoTests",
            dependencies: ["MEGAPickerFileProviderRepo"]
        )
    ]
)
