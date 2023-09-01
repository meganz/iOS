// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "DeviceCenter",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
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
        .package(path: "../../MEGAPresentation"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../../UI/MEGAUIKit"),
        .package(path: "../../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "DeviceCenter",
            dependencies: ["MEGADomain",
                           "MEGAPresentation",
                           "MEGASwiftUI",
                           "MEGAUIKit"]
        ),
        .target(
            name: "DeviceCenterMocks",
            dependencies: ["DeviceCenter"]
        ),
        .testTarget(
            name: "DeviceCenterTests",
            dependencies: ["DeviceCenter",
                           "DeviceCenterMocks",
                           "MEGADomain",
                           "MEGATest",
                           .product(name: "MEGADomainMock", package: "MEGADomain")]
        )
    ]
)
