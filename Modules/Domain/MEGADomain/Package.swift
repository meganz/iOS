// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]), .enableExperimentalFeature("ExistentialAny")]

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
            swiftSettings: settings),
        .target(
            name: "MEGADomainMock",
            dependencies: ["MEGADomain"],
            swiftSettings: settings),
        .testTarget(
            name: "MEGADomainTests",
            dependencies: ["MEGADomain", "MEGADomainMock", "MEGATest"],
            swiftSettings: settings)
    ]
)
