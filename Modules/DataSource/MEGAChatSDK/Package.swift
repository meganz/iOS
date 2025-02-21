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
                           "libwebrtc",
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
                .define("WEBRTC_INCLUDE_INTERNAL_AUDIO_DEVICE"),
                .define("RTC_ENABLE_VP9"),
                .define("WEBRTC_HAVE_SCTP"),
                .define("WEBRTC_LIBRARY_IMPL"),
                .define("ABSL_ALLOCATOR_NOTHROW=1"),
                .define("LIBYUV_DISABLE_SME"),
                .define("LIBYUV_DISABLE_LSX"),
                .define("LIBYUV_DISABLE_LASX"),
                .define("WEBRTC_HAS_NEON"),
                .define("WEBRTC_ARCH_ARM64"),
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
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libnative_api_update_202501.xcframework.zip",
            checksum: "13bd83d6c0ccbaf050861befaffe6bbf4d5f2ca810d49f38c9ec8005f1881a2b"
        ),
        .binaryTarget(
            name: "libnative_video",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libnative_video_update_202501.xcframework.zip",
            checksum: "65c2631eaae4ce39cafa8f26c84a4698d61e7cde9d74200741ec563e19469d13"
        ),
        .binaryTarget(
            name: "libvideocapture_objc",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libvideocapture_objc_update_202501.xcframework.zip",
            checksum: "14a78174fa78b35c2eac1eb6b2977592c3c64a4079bb64ea4be0c0c53fdd4366"
        ),
        .binaryTarget(
            name: "libvideoframebuffer_objc",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libvideoframebuffer_objc_update_202501.xcframework.zip",
            checksum: "12284c57ba0b3594759cfc995a86c24e1f48e5ee9b86d88736bfce8b8876bf19"
        ),
        .binaryTarget(
            name: "libwebsockets",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libwebsockets_xcframework.zip",
            checksum: "d544160a2a4d50dbe3003abc1b4d443b12f536310ab810ae466f6c3fc4b19018"
        ),
        .binaryTarget(
            name: "libwebrtc",
            url: "https://s3.g.s4.mega.io/dmlaaezwz52y37atz56mfvmrvltfagrltbgpr/ios-xcframeworks/libwebrtc_update_202501.xcframework.zip",
            checksum: "7cfa00ac8b743641d3ed642bf5a185c26ddde1948a7eee650d05a5ffc83ce2d4"
        )
    ],
    cxxLanguageStandard: .cxx17
)
