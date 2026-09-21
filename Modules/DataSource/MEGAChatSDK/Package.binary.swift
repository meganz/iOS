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
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20260921.035709/libmegachatsdk.xcframework.20260921.035709.zip",
            checksum: "870899cd496f61db00718361203f963be11531a62175a2fca65a4e7e552bce2a"
        )
    ],
    cxxLanguageStandard: .cxx17
)
