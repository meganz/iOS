// swift-tools-version: 6.0
import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAL10n",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAL10n",
            targets: ["MEGAL10n"]
        )
    ],
    dependencies: [
        .package(path: "../../MEGASharedRepo/MEGABuildTools")
    ],
    targets: [
        .target(
            name: "MEGAL10n",
            swiftSettings: settings,
            plugins: [
                .plugin(name: "SwiftGen", package: "MEGABuildTools")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
