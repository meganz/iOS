// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MEGASDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGASdkCpp",
            targets: ["MEGASdkCpp"]),
        .library(
            name: "MEGASdk",
            targets: ["MEGASdk"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MEGASdkCpp",
            dependencies: [
                "libmegasdk"
            ],
            path: "Sources/MEGASDK",
            exclude: [
                "Package.swift",
                "bindings",
                "cmake",
                "contrib",
                "examples",
                "src/android",
                "src/common/client_adapter_with_sync.cpp",
                "src/file_service/documentation",
                "src/fuse/supported",
                "src/mega_utf8proc_data.c",
                "src/win32",
                "tests",
                "tools"
            ],
            cxxSettings: [
                .headerSearchPath("bindings/ios"),
                .headerSearchPath("include/mega/osx"),
                .headerSearchPath("include/mega/posix"),
                .headerSearchPath("src/common/platform/posix"),
                .headerSearchPath("src/file_service"),
                .headerSearchPath("src/fuse/unsupported"),
                .headerSearchPath("third_party/ccronexpr"),
                .define("ENABLE_CHAT"),
                .define("HAVE_LIBUV"),
                .define("NDEBUG", .when(configuration: .release))
            ],
            linkerSettings: [
                // Frameworks
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
        .target(
            name: "MEGASdk",
            dependencies: ["MEGASdkCpp"],
            path: "Sources/MEGASDK/bindings/ios",
            cxxSettings: [
                .headerSearchPath("../../include"),
                .headerSearchPath("Private"),
                .define("ENABLE_CHAT"),
                .define("HAVE_LIBUV")
            ]
        ),
        .binaryTarget(
            name: "libmegasdk",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libmegasdk_25_09_11.xcframework.zip",
            checksum: "596cbb34cdde786a1df2c1898454cd7c69917f7b6e21d6eb1efbe40db20bad88"
        )
    ],
    cxxLanguageStandard: .cxx17
)
