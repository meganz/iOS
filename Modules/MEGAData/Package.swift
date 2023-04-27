// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MEGAData",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAData",
            targets: ["MEGAData"]),
        .library(
            name: "MEGADataMock",
            targets: ["MEGADataMock"])
    ],
    dependencies: [
        .package(path: "../MEGADomain"),
        .package(path: "../MEGASdk")
    ],
    targets: [
        .target(
            name: "MEGAData",
            dependencies: ["MEGADomain", "MEGASdk"]),
        .target(
            name: "MEGADataMock",
            dependencies: ["MEGAData"]
        ),
        .testTarget(
            name: "MEGADataTests",
            dependencies: ["MEGAData", "MEGADataMock"]),
    ]
)
