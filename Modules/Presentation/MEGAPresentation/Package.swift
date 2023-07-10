// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MEGAPresentation",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAPresentation",
            targets: ["MEGAPresentation"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Domain/MEGAAnalyticsDomain"),
        .package(path: "../../Repository/MEGAData"),
        .package(path: "../../Infrastracture/MEGATest"),
        .package(
            url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "MEGAPresentation",
            dependencies: [
                "MEGAAnalyticsDomain",
                "MEGADomain",
                "MEGAData"
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGAPresentationTests",
            dependencies: ["MEGAPresentation", "MEGATest"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ]
)
