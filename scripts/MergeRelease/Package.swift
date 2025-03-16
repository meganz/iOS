// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MergeRelease",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(path: "../ReleaseScripts/SharedReleaseScript")
    ],
    targets: [
        .executableTarget(
            name: "MergeRelease",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "SharedReleaseScript"
            ]
        ),
    ]
)
