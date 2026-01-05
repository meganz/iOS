// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APMKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "APMKit",
            type: .dynamic,
            targets: [
                "APMKit"
            ]
        )
    ],
    dependencies: [
        .package(path: "../../MEGASharedRepo/MEGASwift")
    ],
    targets: [
        .target(
            name: "APMKit",
            dependencies: ["MEGASwift"]
        ),
        .target(
            name: "APMKitMocks",
            dependencies: [
                "APMKit"
            ]
        ),
        .testTarget(
            name: "APMKitTests",
            dependencies: [
                "APMKit",
                "APMKitMocks"
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
