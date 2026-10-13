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
        .package(path: "../../DataSource/MEGASDK"),
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../MEGASharedRepo/MEGASDKRepo"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../MEGASharedRepo/MEGATest"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../Transfer"),
        .package(path: "../../Infrastracture/MEGABenchmark"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGAPDFViewer",
            dependencies: [
                "MEGAAssets",
                "MEGADomain",
                "MEGAL10n",
                .product(name: "MEGASdk", package: "MEGASDK"),
                "MEGASDKRepo",
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
                "MEGASwift",
                "MEGATest",
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ],
            swiftSettings: settings
        ),
        // Benchmarks with XCTest metrics. They run only with TEST_RUNNER_MEGA_BENCH=1 (see scripts/benchmark.sh).
        .testTarget(
            name: "MEGAPDFViewerBenchmarks",
            dependencies: [
                "MEGAPDFViewer",
                .product(name: "MEGABenchmark", package: "MEGABenchmark")
            ],
            exclude: ["Limits.json"],
            resources: [.copy("OutlineFixtures")],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
