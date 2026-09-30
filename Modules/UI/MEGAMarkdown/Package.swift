// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAMarkdown",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MEGAMarkdown",
            targets: ["MEGAMarkdown"])
    ],
    dependencies: [
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        // Markdown parser (cmark-gfm, C). Pinned: parser output must not change without review.
        .package(url: "https://github.com/swiftlang/swift-cmark.git", exact: "0.9.0")
    ],
    targets: [
        .target(
            name: "MEGAMarkdown",
            dependencies: [
                "MEGADesignToken",
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark")
            ],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
