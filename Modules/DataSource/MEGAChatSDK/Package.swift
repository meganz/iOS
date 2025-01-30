// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MEGAChatSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAChatSdkCpp",
            targets: ["MEGAChatSdkCpp"]),
        .library(
            name: "MEGAChatSdk",
            targets: ["MEGAChatSdk"])
    ],
    dependencies: [
        .package(path: "../MEGASdk")
    ],
    targets: [
        .target(
            name: "MEGAChatSdkCpp",
            dependencies: ["libnative_api",
                           "libnative_video",
                           "libvideocapture_objc",
                           "libvideoframebuffer_objc",
                           "libwebsockets",
                           .product(name: "MEGASdkCpp", package: "MEGASdk")],
            path: "Sources/MEGAChatSDK",
            exclude: ["bindings",
                      "contrib",
                      "examples",
                      "tests",
                      "webrtc-build"],
            publicHeadersPath: "src",
            cxxSettings: [
                .headerSearchPath("bindings/Objective-C/3rdparty/include"),
                .headerSearchPath("bindings/Objective-C/3rdparty/webrtc"),
                .headerSearchPath("bindings/Objective-C/3rdparty/webrtc/sdk/objc/base"),
                .headerSearchPath("bindings/Objective-C/3rdparty/webrtc/sdk/objc"),
                .headerSearchPath("src/rtcModule"),
                .headerSearchPath("src/base"),
                .headerSearchPath("src/strongvelope"),
                .headerSearchPath("third-party"),
                .headerSearchPath("bindings/Objective-C/3rdparty/webrtc/third_party/boringssl/src/include"),
                .headerSearchPath("bindings/Objective-C/3rdparty/webrtc/third_party/abseil-cpp"),
                .headerSearchPath("bindings/Objective-C/3rdparty/webrtc/third_party/libyuv/include"),
                .define("ENABLE_CHAT"),
                .define("HAVE_CONFIG_H"),
                .define("_DARWIN_C_SOURCE"),
                .define("ENABLE_WEBRTC"),
                .define("WEBRTC_POSIX"),
                .define("WEBRTC_MAC"),
                .define("WEBRTC_IOS"),
                .define("V8_DEPRECATION_WARNINGS"),
                .define("NO_TCMALLOC"),
                .define("CHROMIUM_BUILD"),
                .define("CR_XCODE_VERSION=0901"),
                .define("CR_CLANG_REVISION=\"313786-1\""),
                .define("_FORTIFY_SOURCE=2"),
                .define("NVALGRIND"),
                .define("DYNAMIC_ANNOTATIONS_ENABLED=0"),
                .define("NS_BLOCK_ASSERTIONS=1"),
                .define("WEBRTC_ENABLE_PROTOBUF=1"),
                .define("WEBRTC_INCLUDE_INTERNAL_AUDIO_DEVICE"),
                .define("RTC_DISABLE_VP9"),
                .define("HAVE_SCTP"),
                .define("WEBRTC_NON_STATIC_TRACE_EVENT_HANDLERS=1"),
                .define("NDEBUG", .when(configuration: .release))
            ]
        ),
        .target(
            name: "MEGAChatSdk",
            dependencies: ["MEGAChatSdkCpp",
                           .product(name: "MEGASdk", package: "MEGASdk")],
            path: "Sources/MEGAChatSDK/bindings/Objective-C",
            cxxSettings: [
                .headerSearchPath("3rdparty/include"),
                .headerSearchPath("Private"),
                .define("ENABLE_CHAT")
            ]
        ),
        .binaryTarget(
            name: "libnative_api",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libnative_api_xcframework.zip",
            checksum: "7cd3473272c32c63ffd885ce51997d30e8114e8ad47969eb455c06e339e11f0d"
        ),
        .binaryTarget(
            name: "libnative_video",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libnative_video_xcframework.zip",
            checksum: "d7d4c14f69575117fae5288e8f43c8c9c6d7543642b062428d9238f1eead371e"
        ),
        .binaryTarget(
            name: "libvideocapture_objc",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libvideocapture_objc_xcframework.zip",
            checksum: "6bb5e945014b98479c1e5614d2ddf6d51d0c20bbaa1ab5d7e7af1d22c3c19a99"
        ),
        .binaryTarget(
            name: "libvideoframebuffer_objc",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libvideoframebuffer_objc_xcframework.zip",
            checksum: "ea0262b787a5cd520adfb64dc4bc94e5312b588825d3cb272cd5596d067e4fb1"
        ),
        .binaryTarget(
            name: "libwebsockets",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libwebsockets_xcframework.zip",
            checksum: "d544160a2a4d50dbe3003abc1b4d443b12f536310ab810ae466f6c3fc4b19018"
        )
    ],
    cxxLanguageStandard: .cxx17
)
