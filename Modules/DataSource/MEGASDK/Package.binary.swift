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
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20261026.092635/libmegasdk.xcframework.20261026.092635.zip",
            checksum: "78742e682cc23894c253c9db1d7fc517379d747ebbf8155084017378b42070c9"
        ),
        .binaryTarget(
            name: "libmegathirdparty",
            url: "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/xcframework/20261026.092635/libmegathirdparty.xcframework.20261026.092635.zip",
            checksum: "012e835e62d0f33c314f9c055e2eb5c91682a9982376d2a15dd0fe1afa6dd51d"
        )
    ],
    cxxLanguageStandard: .cxx17
)
