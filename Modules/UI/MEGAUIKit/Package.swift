// swift-tools-version: 5.10

import PackageDescription

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
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGAUIKitTests",
            dependencies: ["MEGAUIKit"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ]
)
