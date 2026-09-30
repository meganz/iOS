// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ContinueWhereYouLeftOff",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ContinueWhereYouLeftOff",
            targets: ["ContinueWhereYouLeftOff"]
        ),
        .library(
            name: "ContinueWhereYouLeftOffMock",
            targets: ["ContinueWhereYouLeftOffMock"]
        )
    ],
    dependencies: [
        // Domain
        .package(path: "../../Domain/MEGADomain"),

        // Infrastructure
        .package(path: "../../Infrastracture/MEGAFoundation"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),

        // Test
        .package(path: "../../MEGASharedRepo/MEGATest")
    ],
    targets: [
        .target(
            name: "ContinueWhereYouLeftOff",
            dependencies: [
                "MEGADomain",
                "MEGAFoundation",
                "MEGASwift"
            ]
        ),
        .target(
            name: "ContinueWhereYouLeftOffMock",
            dependencies: [
                "ContinueWhereYouLeftOff",
                "MEGASwift"
            ]
        ),
        .testTarget(
            name: "ContinueWhereYouLeftOffTests",
            dependencies: [
                "ContinueWhereYouLeftOff",
                "ContinueWhereYouLeftOffMock",
                "MEGADomain",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                "MEGASwift",
                "MEGATest"
            ]
        )
    ]
)
