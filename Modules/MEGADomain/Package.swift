// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MEGADomain",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(
            name: "MEGADomain",
            targets: ["MEGADomain"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGADomain",
            dependencies: []),
        .testTarget(
            name: "MEGADomainTests",
            dependencies: ["MEGADomain"]),
    ]
)
