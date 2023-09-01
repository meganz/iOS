// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "Settings",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "Settings",
            targets: ["Settings"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../MEGAPresentation")
    ],
    targets: [
        .target(
            name: "Settings",
            dependencies: ["MEGADomain", "MEGAPresentation"]),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings",
                           .product(name: "MEGADomainMock", package: "MEGADomain")])
    ]
)
