// swift-tools-version: 6.0
import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGATextEditor",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MEGATextEditor",
            targets: ["MEGATextEditor"]
        )
    ],
    dependencies: [
        .package(path: "../../UI/MEGAMarkdown"),
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../Infrastracture/MEGASnapshot"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGATextEditor",
            dependencies: [
                .product(name: "MEGAMarkdown", package: "MEGAMarkdown"),
                .product(name: "MEGAMarkdownEditor", package: "MEGAMarkdown"),
                "MEGADomain",
                "MEGAL10n",
                "MEGAAssets",
                "MEGASwift",
                "MEGADesignToken"
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGATextEditorTests",
            dependencies: [
                "MEGATextEditor",
                .product(name: "MEGAMarkdown", package: "MEGAMarkdown"),
                .product(name: "MEGAMarkdownEditor", package: "MEGAMarkdown"),
                "MEGADomain",
                "MEGAL10n"
            ],
            swiftSettings: settings
        ),
        // Image snapshots. They run only from scripts/snapshot.sh, on a pinned simulator.
        .testTarget(
            name: "MEGATextEditorSnapshotTests",
            dependencies: [
                "MEGATextEditor",
                .product(name: "MEGASnapshot", package: "MEGASnapshot")
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
