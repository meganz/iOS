// swift-tools-version: 6.0
import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAShareLink",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MEGAShareLink",
            targets: ["MEGAShareLink"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGAShareLink",
            dependencies: [
                "MEGAAssets",
                "MEGADesignToken",
                "MEGADomain",
                "MEGAL10n"
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAShareLinkTests",
            dependencies: ["MEGAShareLink"],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
