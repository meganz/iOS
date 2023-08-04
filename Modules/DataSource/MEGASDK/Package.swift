// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MEGASDK",
    platforms: [
        .iOS(.v14)
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
            dependencies: ["libcryptopp",
                           "libmediainfo",
                           "libuv",
                           "libcurl",
                           "libsodium",
                           "libwebrtc",
                           "libzen"],
            path: "Sources/MEGASDK",
            exclude: ["examples",
                      "tests",
                      "doc",
                      "contrib",
                      "bindings",
                      "src/win32",
                      "src/wincurl",
                      "src/mega_utf8proc_data.c",
                      "src/thread/libuvthread.cpp",
                      "src/osx/fs.cpp"],
            cxxSettings: [
                .headerSearchPath("bindings/ios"),
                .headerSearchPath("include/mega/posix"),
                .headerSearchPath("bindings/ios/3rdparty/webrtc/third_party/boringssl/src/include"),
                .define("ENABLE_CHAT"),
                .define("HAVE_LIBUV"),
                .define("NDEBUG", .when(configuration: .release))
            ],
            linkerSettings: [
                // Frameworks
                .linkedFramework("QuickLookThumbnailing"),
                // Libraries
                .linkedLibrary("resolv"),
                .linkedLibrary("z"),
                .linkedLibrary("sqlite3"),
                .linkedLibrary("icucore")
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
            name: "libcryptopp",
            path: "Sources/MEGASDK/bindings/ios/3rdparty/lib/libcryptopp.xcframework"
        ),
        .binaryTarget(
            name: "libmediainfo",
            path: "Sources/MEGASDK/bindings/ios/3rdparty/lib/libmediainfo.xcframework"
        ),
        .binaryTarget(
            name: "libuv",
            path: "Sources/MEGASDK/bindings/ios/3rdparty/lib/libuv.xcframework"
        ),
        .binaryTarget(
            name: "libcurl",
            path: "Sources/MEGASDK/bindings/ios/3rdparty/lib/libcurl.xcframework"
        ),
        .binaryTarget(
            name: "libsodium",
            path: "Sources/MEGASDK/bindings/ios/3rdparty/lib/libsodium.xcframework"
        ),
        .binaryTarget(
            name: "libwebrtc",
            path: "Sources/MEGASDK/bindings/ios/3rdparty/lib/libwebrtc.xcframework"
        ),
        .binaryTarget(
            name: "libzen",
            path: "Sources/MEGASDK/bindings/ios/3rdparty/lib/libzen.xcframework"
        )
    ],
    cxxLanguageStandard: .cxx14
)
