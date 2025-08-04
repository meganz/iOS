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
                "libmediainfo",
                "libzen",
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
                "src/fuse/common/database_builder.cpp",
                "src/fuse/common/directory_inode.cpp",
                "src/fuse/common/file_cache.cpp",
                "src/fuse/common/file_extension_db.cpp",
                "src/fuse/common/file_info.cpp",
                "src/fuse/common/file_inode.cpp",
                "src/fuse/common/file_io_context.cpp",
                "src/fuse/common/inode.cpp",
                "src/fuse/common/inode_cache.cpp",
                "src/fuse/common/inode_db.cpp",
                "src/fuse/common/mega",
                "src/fuse/common/mount.cpp",
                "src/fuse/common/mount_db.cpp",
                "src/fuse/common/testing",
                "src/fuse/supported",
                "src/mega_utf8proc_data.c",
                "src/win32",
                "tests",
                "tools"
            ],
            cxxSettings: [
                .headerSearchPath("bindings/ios"),
                .headerSearchPath("include/mega/posix"),
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
            name: "libmediainfo",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libmediainfo_xcframework.zip",
            checksum: "24fdbe1e3df3642799b1c890d5c810c88088bbe2a1d7bd34c766587f7405b0fa"
        ),
        .binaryTarget(
            name: "libzen",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libzen_xcframework.zip",
            checksum: "f3759e829d921875c4d9ec55354b225e8c5354488ca492d777bf10b0e9d38ebb"
        ),
        .binaryTarget(
            name: "libmegasdk",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libmegasdk_25_07_31.xcframework.zip",
            checksum: "9fabbc58b13b5b2e8cff1455b51c37bc76f30239f96b223d04bc4891e46d5a81"
        )
    ],
    cxxLanguageStandard: .cxx17
)
