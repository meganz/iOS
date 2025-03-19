// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PrepareHotfix",
    platforms: [.macOS(.v14)],
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

