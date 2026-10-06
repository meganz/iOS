// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

// Image snapshots of SwiftUI views. Only snapshot test targets depend on it. Run them with scripts/snapshot.sh.
let package = Package(
    name: "MEGASnapshot",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MEGASnapshot",
            targets: ["MEGASnapshot"])
    ],
    dependencies: [
        // 1.17.6 needs only swift-syntax. 1.18+ adds two more packages.
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.17.6"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGASnapshot",
            dependencies: [
                "MEGADesignToken",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
