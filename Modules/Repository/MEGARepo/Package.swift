// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGARepo",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGARepo",
            targets: ["MEGARepo"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(url: "https://github.com/meganz/SAMKeychain.git", from: "2.0.0")
        
    ],
    targets: [
        .target(
            name: "MEGARepo",
            dependencies: [
                "MEGADomain",
                "MEGASwift",
                "SAMKeychain"
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGARepoTests",
            dependencies: ["MEGARepo", "MEGASwift"],
            resources: [.process("Resources")],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
