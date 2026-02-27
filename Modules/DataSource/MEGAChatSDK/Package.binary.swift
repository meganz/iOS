// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MEGAChatSDK",
    platforms: [
        .iOS(.v16)
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
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/test/libmegachatsdk-IOS-11012-56953d99fae1d7b118111a9f29a18f65c3dc6eb5a66c6bfd114fc33c87e8a660.xcframework.zip",
            checksum: "56953d99fae1d7b118111a9f29a18f65c3dc6eb5a66c6bfd114fc33c87e8a660"
        )
    ],
    cxxLanguageStandard: .cxx17
)
