// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SharedReleaseScript",
    products: [
        .library(
            name: "SharedReleaseScript",
            targets: ["SharedReleaseScript"]
        ),
    ],
    targets: [
        .target(name: "SharedReleaseScript")
    ]
)
