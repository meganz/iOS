// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAUIKit",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAUIKit",
            targets: ["MEGAUIKit"])
    ],
    dependencies: [
        .package(path: "../MEGAUI"),
        .package(path: "../../Infrastracture/MEGASwift")
    ],
    targets: [
        .target(
            name: "MEGAUIKit",
            dependencies: ["MEGAUI", "MEGASwift"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAUIKitTests",
            dependencies: ["MEGAUIKit"],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
