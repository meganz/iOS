// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MEGAChatSDK",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MEGAChatSdk",
            targets: ["MEGAChatSdk"])
    ],
    dependencies: [
        .package(path: "../MEGASdk")
    ],
    targets: [
        .target(
            name: "MEGAChatSdk",
            dependencies: ["libmegachatsdk", .product(name: "MEGASdk", package: "MEGASdk"), .product(name: "MEGAThirdParty", package: "MEGASdk")],
            path: "Sources/MEGAChatSDK/bindings/Objective-C",
            cxxSettings: [
                .headerSearchPath("3rdparty/include"),
                .headerSearchPath("Private"),
                .define("ENABLE_CHAT")
            ]
        ),
        .binaryTarget(
            name: "libmegachatsdk",
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20260921.015910/libmegachatsdk.xcframework.20260921.015910.zip",
            checksum: "e6751b309c68a10b7cea57244bb4b7802beef13f1f39dd8cc7bd0bd423443e88"
        )
    ],
    cxxLanguageStandard: .cxx17
)
