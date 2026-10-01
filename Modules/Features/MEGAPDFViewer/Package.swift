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
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../MEGASharedRepo/MEGATest"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../Transfer"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGAPDFViewer",
            dependencies: [
                "MEGAAssets",
                "MEGADomain",
                "MEGAL10n",
                "MEGASwiftUI",
                "MEGADesignToken",
                "Transfer"
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAPDFViewerTests",
            dependencies: [
                "MEGAPDFViewer",
                "MEGATest",
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
