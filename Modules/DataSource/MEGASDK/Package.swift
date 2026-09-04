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
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20260904.073516/libmegasdk.xcframework.20260904.073516.zip",
            checksum: "a128faef0971e18e87cdbc0f01c48f51d652218ae23c20e0d6618405075682aa"
        ),
        .binaryTarget(
            name: "libmegathirdparty",
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20260904.073516/libmegathirdparty.xcframework.20260904.073516.zip",
            checksum: "094368eb97c3fe2cb99d0ec24dedd5fa13e542e6eaf1d562bc50b62b2a23918e"
        )
    ],
    cxxLanguageStandard: .cxx17
)
