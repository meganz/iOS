// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MEGADomain",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGADomain",
            targets: ["MEGADomain"]),
        .library(
            name: "MEGADomainMock",
            targets: ["MEGADomainMock"])
    ],
    dependencies: [
        .package(path: "../../Infrastracture/MEGASwift"),
        .package(path: "../../Infrastracture/MEGAFoundation")
    ],
    targets: [
        .target(
            name: "MEGADomain",
            dependencies: ["MEGASwift", "MEGAFoundation"]),
        .target(
            name: "MEGADomainMock",
            dependencies: ["MEGADomain"]),
        .testTarget(
            name: "MEGADomainTests",
            dependencies: ["MEGADomain", "MEGADomainMock"])
    ]
)
