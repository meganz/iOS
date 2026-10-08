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
            targets: ["MEGAMarkdown"]),
        .library(
            name: "MEGAMarkdownEditor",
            targets: ["MEGAMarkdownEditor"])
    ],
    dependencies: [
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        // Markdown parser (cmark-gfm, C). Pinned: parser output must not change without review.
        .package(url: "https://github.com/swiftlang/swift-cmark.git", exact: "0.9.0"),
        .package(path: "../../Infrastracture/MEGAFoundation"),
        .package(path: "../../Infrastracture/MEGABenchmark"),
        .package(path: "../../Infrastracture/MEGASnapshot")
    ],
    targets: [
        .target(
            name: "MEGAMarkdown",
            dependencies: [
                "MEGADesignToken",
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
                "MEGAFoundation"
            ],
            swiftSettings: settings),
        // The rich editor: the model (Markdown import and export, editing, undo, clipboard) and its UI.
        .target(
            name: "MEGAMarkdownEditor",
            dependencies: ["MEGAMarkdown", "MEGADesignToken", "MEGAFoundation"],
            resources: [.process("Resources")],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAMarkdownTests",
            dependencies: [
                "MEGAMarkdown",
                .product(name: "cmark-gfm", package: "swift-cmark")
            ],
            resources: [.copy("Fixtures")],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAMarkdownEditorTests",
            dependencies: ["MEGAMarkdownEditor", "MEGAMarkdown"],
            swiftSettings: settings),
        // Editor tests in a window on the simulator. Results depend on the simulator and on timing (see EDITOR-UI.md),
        // so the CI test plan has this target turned off.
        .testTarget(
            name: "MEGAMarkdownEditorHostedTests",
            dependencies: ["MEGAMarkdownEditor", "MEGAMarkdown"],
            swiftSettings: settings),
        // Benchmarks with XCTest metrics. They run only with TEST_RUNNER_MEGA_BENCH=1 (see scripts/benchmark.sh).
        .testTarget(
            name: "MEGAMarkdownBenchmarks",
            dependencies: [
                "MEGAMarkdown",
                "MEGAMarkdownEditor",
                .product(name: "MEGABenchmark", package: "MEGABenchmark")
            ],
            exclude: ["Limits.json", "Skipped.json"],
            swiftSettings: settings),
        // Image snapshots. They run only from scripts/snapshot.sh, on a pinned simulator.
        .testTarget(
            name: "MEGAMarkdownSnapshotTests",
            dependencies: [
                "MEGAMarkdown",
                "MEGAMarkdownEditor",
                "MEGADesignToken",
                .product(name: "MEGASnapshot", package: "MEGASnapshot")
            ],
            exclude: ["__Snapshots__"],
            resources: [.copy("Images")],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
