// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MEGAChatSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
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
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
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
                      "src/dummyCrypto.cpp",
                      "tests",
                      "webrtc-build",
                      "src/videoRenderer_Qt.cpp",
                      "src/videoRenderer_objc.mm",
                      "src/base/promise-test.cpp"],
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
            path: "Sources/MEGAChatSDK/bindings/Objective-C/3rdparty/lib/libnative_api.xcframework"
        ),
        .binaryTarget(
            name: "libnative_video",
            path: "Sources/MEGAChatSDK/bindings/Objective-C/3rdparty/lib/libnative_video.xcframework"
        ),
        .binaryTarget(
            name: "libvideocapture_objc",
            path: "Sources/MEGAChatSDK/bindings/Objective-C/3rdparty/lib/libvideocapture_objc.xcframework"
        ),
        .binaryTarget(
            name: "libvideoframebuffer_objc",
            path: "Sources/MEGAChatSDK/bindings/Objective-C/3rdparty/lib/libvideoframebuffer_objc.xcframework"
        ),
        .binaryTarget(
            name: "libwebsockets",
            path: "Sources/MEGAChatSDK/bindings/Objective-C/3rdparty/lib/libwebsockets.xcframework"
        )
    ],
    cxxLanguageStandard: .cxx17
)
