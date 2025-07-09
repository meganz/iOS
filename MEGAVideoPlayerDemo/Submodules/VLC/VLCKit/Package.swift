// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VLCKit",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "VLCKit", targets: ["VLCKit"]),
    ],
    dependencies: [],
    targets: [
        // README:
        // This local binary must be compiled first by running `generate.sh` from the Package directory.
        // This is temporary, on production environment we can host the binary in our servers
        .binaryTarget(
            name: "VLCKit",
            path: ".tmp/VLCKit.xcframework"
        ),
        .target(
            name: "VLCKitSPM",
            dependencies: [.target(name: "VLCKit")],
            linkerSettings: [
                .linkedFramework("QuartzCore"),
                .linkedFramework("CoreText"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Security"),
                .linkedFramework("CFNetwork"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("OpenGLES"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("VideoToolbox"),
                .linkedFramework("CoreMedia"),
                .linkedLibrary("c+"),
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv")
            ]
        )
    ]
)
