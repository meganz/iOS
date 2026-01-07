// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ErrorParsingKit",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/davidahouse/XCResultKit.git", from: "1.2.2")
    ],
    targets: [
        .executableTarget(
            name: "ErrorParsingKit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "XCResultKit"
            ]
        ),
    ]
)
