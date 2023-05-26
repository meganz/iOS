// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MEGAUIKit",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAUIKit",
            targets: ["MEGAUIKit"]),
    ],
    dependencies: [
        .package(path: "../MEGAUI"),
        .package(path: "../../Infrastracture/MEGASwift")
    ],
    targets: [
        .target(
            name: "MEGAUIKit",
            dependencies: ["MEGAUI", "MEGASwift"]),
        .testTarget(
            name: "MEGAUIKitTests",
            dependencies: ["MEGAUIKit"]),
    ]
)
