// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MEGADomain",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
    ],
    products: [
        .library(
            name: "MEGADomain",
            targets: ["MEGADomain"]),
        .library(
            name: "MEGADomainMock",
            targets: ["MEGADomainMock"])
    ],
    dependencies: [
        .package(path: "../../Infrastracture/MEGASwift"),
        .package(path: "../../Infrastracture/MEGAFoundation"),
        .package(path: "../../Infrastracture/MEGATest")
    ],
    targets: [
        .target(
            name: "MEGADomain",
            dependencies: ["MEGASwift", "MEGAFoundation"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .target(
            name: "MEGADomainMock",
            dependencies: ["MEGADomain"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]),
        .testTarget(
            name: "MEGADomainTests",
            dependencies: ["MEGADomain", "MEGADomainMock", "MEGATest"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")])
    ]
)
