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
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20261116.184839/libmegasdk.xcframework.20261116.184839.zip",
            checksum: "767ec38ac8d603445f8d59eda78edee4e26024beb1f8c7cf62251be5233f7847"
        ),
        .binaryTarget(
            name: "libmegathirdparty",
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20261116.184839/libmegathirdparty.xcframework.20261116.184839.zip",
            checksum: "110a51c11d35503951f590617ad07fd8acc9a69435d66116124a6840ff5b2474"
        )
    ],
    cxxLanguageStandard: .cxx17
)
