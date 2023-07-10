// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MEGAAnalyticsDomain",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGAAnalyticsDomain",
            targets: ["MEGAAnalyticsDomain"]),
        .library(
            name: "MEGAAnalyticsDomainMock",
            targets: ["MEGAAnalyticsDomainMock"])
    ],
    dependencies: [
        .package(path: "../MEGADomain"),
        .package(path: "../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "MEGAAnalyticsDomain",
            dependencies: ["MEGADomain"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "MEGAAnalyticsDomainMock",
            dependencies: ["MEGAAnalyticsDomain"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "MEGAAnalyticsDomainTests",
            dependencies: [
                "MEGAAnalyticsDomain",
                "MEGAAnalyticsDomainMock",
                "MEGATest"
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        )
    ]
)
