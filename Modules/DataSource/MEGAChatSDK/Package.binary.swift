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
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20261014.120135/libmegachatsdk.xcframework.20261014.120135.zip",
            checksum: "1eabaf73bf625a0a25b90f7f3fd6fed0ac2647f318ecdb28c8eee530a9a15fc9"
        )
    ],
    cxxLanguageStandard: .cxx17
)
