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
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20261030.005659/libmegachatsdk.xcframework.20261030.005659.zip",
            checksum: "3605c193d4b66c67b95c1fc6346bccbd2fd7d0a4f54580cb19b78c148ede38d9"
        )
    ],
    cxxLanguageStandard: .cxx17
)
