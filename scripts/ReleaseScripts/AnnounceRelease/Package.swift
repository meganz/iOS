// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AnnounceRelease",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../../ReleaseScripts/SharedReleaseScript")
    ],
    targets: [
        .executableTarget(
            name: "AnnounceRelease",
            dependencies: ["SharedReleaseScript"]
        )
    ]
)
