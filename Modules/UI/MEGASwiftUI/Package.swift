// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MEGASwiftUI",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGASwiftUI",
            targets: ["MEGASwiftUI"])
    ],
    dependencies: [
        .package(path: "../MEGAUI"),
        .package(path: "../../MEGAPresentation")
    ],
    targets: [
        .target(
            name: "MEGASwiftUI",
            dependencies: ["MEGAUI", "MEGAPresentation"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGASwiftUITests",
            dependencies: ["MEGASwiftUI"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ]
)
