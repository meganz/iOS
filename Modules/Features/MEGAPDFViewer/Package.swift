// swift-tools-version: 6.0
import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAPDFViewer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MEGAPDFViewer",
            targets: ["MEGAPDFViewer"]
        )
    ],
    dependencies: [
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGAPDFViewer",
            dependencies: [
                "MEGAAssets",
                "MEGAL10n",
                "MEGADesignToken",
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
