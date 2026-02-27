// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MEGASDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGASdk",
            targets: ["MEGASdk"]
        ),
        .library(
            name: "MEGAThirdParty",
            targets: ["libmegathirdparty"]
        )
    ],
    targets: [
        .target(
            name: "MEGASdk",
            dependencies: [
                "libmegasdk",
                "libmegathirdparty"
            ],
            path: "Sources/MEGASDK/bindings/ios",
            cxxSettings: [
                .headerSearchPath("Private"),
                .define("ENABLE_CHAT"),
                .define("HAVE_LIBUV")
            ],
            linkerSettings: [
                .linkedFramework("QuickLookThumbnailing"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("CFNetwork"),
                .linkedFramework("Security"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ImageIO"),
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedLibrary("z"),
                .linkedLibrary("sqlite3")
            ]
        ),
        .binaryTarget(
            name: "libmegasdk",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/test/libmegasdk-IOS-11012-13cd3f6e62ec0f99591f76e9541225c3c4cb7e702b455c2d64c7654939c67095.xcframework.zip",
            checksum: "13cd3f6e62ec0f99591f76e9541225c3c4cb7e702b455c2d64c7654939c67095"
        ),
        .binaryTarget(
            name: "libmegathirdparty",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/test/libmegathirdparty-IOS-11012-f3bca5a0f000302e67d264e7b8044a8d9dc8789abf47ce979a5e20222c691047.xcframework.zip",
            checksum: "f3bca5a0f000302e67d264e7b8044a8d9dc8789abf47ce979a5e20222c691047"
        )
    ],
    cxxLanguageStandard: .cxx17
)
