// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MEGASwiftUI",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGASwiftUI",
            targets: ["MEGASwiftUI"]),
        .library(
            name: "MEGASwiftUIMock",
            targets: ["MEGASwiftUIMock"])
    ],
    dependencies: [
        .package(path: "../MEGAUI"),
        .package(path: "../../Presentation/MEGAPresentation"),
        .package(path: "../../Infrastracture/MEGAFoundation"),
        .package(path: "../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "MEGASwiftUI",
            dependencies: [
                "MEGAUI",
                "MEGAPresentation",
                "MEGAFoundation"
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "MEGASwiftUIMock",
            dependencies: ["MEGASwiftUI", "MEGAFoundation"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGASwiftUITests",
            dependencies: ["MEGASwiftUI",
                           "MEGASwiftUIMock",
                           "MEGATest"
                          ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ]
)
