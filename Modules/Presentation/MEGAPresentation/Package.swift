// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MEGAPresentation",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAPresentation",
            targets: ["MEGAPresentation"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Repository/MEGAData")
    ],
    targets: [
        .target(
            name: "MEGAPresentation",
            dependencies: ["MEGADomain", "MEGAData"]),
        .testTarget(
            name: "MEGAPresentationTests",
            dependencies: ["MEGAPresentation"])
    ]
)
