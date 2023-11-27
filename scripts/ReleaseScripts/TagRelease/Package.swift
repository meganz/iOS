// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TagRelease",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../../ReleaseScripts/SharedReleaseScript")
    ],
    targets: [
        .executableTarget(
            name: "TagRelease",
            dependencies: ["SharedReleaseScript"]
        )
    ]
)
