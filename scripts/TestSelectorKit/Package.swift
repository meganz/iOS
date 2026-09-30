// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TestSelectorKit",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(name: "TestSelectorKit"),
        .testTarget(
            name: "TestSelectorKitTests",
            dependencies: ["TestSelectorKit"]
        )
    ]
)
