// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAPickerFileProviderDomain",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGAPickerFileProviderDomain",
            targets: ["MEGAPickerFileProviderDomain"]
        )
    ],
    dependencies: [
        .package(path: "../MEGADomain"),
        .package(path: "../../MEGASharedRepo/MEGATest")
    ],
    targets: [
        .target(
            name: "MEGAPickerFileProviderDomain",
            dependencies: ["MEGADomain"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAPickerFileProviderDomainTests",
            dependencies: [
                "MEGAPickerFileProviderDomain",
                "MEGATest",
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
