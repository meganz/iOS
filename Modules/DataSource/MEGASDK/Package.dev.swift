// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MEGASDK",
    platforms: [
        // Stays at .v16 because MEGASharedRepo packages (still .v16) depend on this package;
        // bump to .v17 together with MEGASharedRepo.
        .iOS(.v16)
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
                "libmegathirdparty"
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
                "src/common/platform/windows",
                "src/file_service/documentation",
                "src/fuse/supported",
                "third_party/utf8proc/utf8proc_data.c",
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
                .headerSearchPath("third_party"),
                .define("ENABLE_CHAT"),
                .define("HAVE_LIBUV"),
                .define("MEGA_USE_WSUPLOAD"),
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
            name: "libmegathirdparty",
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20261026.092635/libmegathirdparty.xcframework.20261026.092635.zip",
            checksum: "012e835e62d0f33c314f9c055e2eb5c91682a9982376d2a15dd0fe1afa6dd51d"
        )
    ],
    cxxLanguageStandard: .cxx17
)
