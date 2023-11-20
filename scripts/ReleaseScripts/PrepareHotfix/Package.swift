// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PrepareHotfix",
    dependencies: [
        .package(path: "../../ReleaseScripts/SharedReleaseScript")
    ],
    targets: [
        .executableTarget(
            name: "PrepareHotfix",
            dependencies: ["SharedReleaseScript"]
        )
    ]
)

