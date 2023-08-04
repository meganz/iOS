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
            targets: ["DeviceCenter"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../MEGAPresentation")
    ],
    targets: [
        .target(
            name: "DeviceCenter",
            dependencies: ["MEGADomain", "MEGAPresentation"]),
        .testTarget(
            name: "DeviceCenterTests",
            dependencies: ["DeviceCenter",
                           .product(name: "MEGADomainMock", package: "MEGADomain")])
    ]
)
