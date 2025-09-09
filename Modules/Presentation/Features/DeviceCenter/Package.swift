// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "DeviceCenter",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DeviceCenter",
            targets: ["DeviceCenter"]),
        .library(
            name: "DeviceCenterMocks",
            targets: ["DeviceCenterMocks"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../MEGAAppPresentation"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../../UI/MEGAUIKit"),
        .package(path: "../../../Infrastracture/MEGATest"),
        .package(path: "../../../Localization/MEGAL10n"),
        .package(path: "../../../MEGAAssets"),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main")
    ],
    targets: [
        .target(
            name: "DeviceCenter",
            dependencies: [
                "MEGADomain",
                "MEGAAppPresentation",
                "MEGASwiftUI",
                "MEGAL10n",
                "MEGAUIKit",
                "MEGADesignToken",
                "MEGAAssets"
            ],
            swiftSettings: settings
        ),
        .target(
            name: "DeviceCenterMocks",
            dependencies: [
                "DeviceCenter"
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "DeviceCenterTests",
            dependencies: [
                "DeviceCenter",
                "DeviceCenterMocks",
                "MEGADomain",
                "MEGATest",
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
