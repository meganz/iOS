// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MEGASwiftUI",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(
            name: "MEGASwiftUI",
            targets: ["MEGASwiftUI"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGASwiftUI",
            dependencies: []),
        .testTarget(
            name: "MEGASwiftUITests",
            dependencies: ["MEGASwiftUI"]),
    ]
)
