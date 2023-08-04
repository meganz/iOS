// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MEGARepo",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGARepo",
            targets: ["MEGARepo"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain")

    ],
    targets: [
        .target(
            name: "MEGARepo",
            dependencies: ["MEGADomain"])
    ]
)
