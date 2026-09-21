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
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20260921.015910/libmegasdk.xcframework.20260921.015910.zip",
            checksum: "9f4450beff7007340555c68756837e7ffd54ab1fb3ee16172f3a85e191809bba"
        ),
        .binaryTarget(
            name: "libmegathirdparty",
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20260921.015910/libmegathirdparty.xcframework.20260921.015910.zip",
            checksum: "371525485a8c3b7f006e15ef64b45af1d2e2684c26fa154f621134b23772b9ae"
        )
    ],
    cxxLanguageStandard: .cxx17
)
