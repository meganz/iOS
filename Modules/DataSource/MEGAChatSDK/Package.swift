// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MEGAChatSDK",
    platforms: [
        .iOS(.v16)
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
            dependencies: [
                .product(name: "MEGASdkCpp", package: "MEGASdk")
            ],
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
        )
    ],
    cxxLanguageStandard: .cxx17
)
