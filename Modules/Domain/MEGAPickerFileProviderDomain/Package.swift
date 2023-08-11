// swift-tools-version: 5.8

import PackageDescription

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
            dependencies: ["MEGADomain"]
        ),
        .testTarget(
            name: "MEGAPickerFileProviderDomainTests",
            dependencies: ["MEGAPickerFileProviderDomain"]
        )
    ]
)
