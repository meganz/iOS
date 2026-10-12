// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "CloudDrive",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CloudDrive",
            targets: ["CloudDrive"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../MEGASharedRepo/MEGAUIComponent"),
        .package(path: "../../Infrastracture/MEGASnapshot"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(path: "../../MEGASharedRepo/MEGATest")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CloudDrive",
            dependencies: [
                "MEGAAppPresentation",
                "MEGAAssets",
                "MEGADesignToken",
                "MEGADomain",
                "MEGAL10n",
                "MEGASwift",
                "MEGASwiftUI",
                "MEGAUIComponent",
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "CloudDriveTests",
            dependencies: [
                "CloudDrive",
                "MEGAL10n",
                "MEGASwift",
                "MEGASwiftUI",
                "MEGATest",
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios"),
                .product(
                    name: "MEGADomainMock",
                    package: "MEGADomain"
                ),
                .product(
                    name: "MEGAAppPresentationMock",
                    package: "MEGAAppPresentation"
                ),
                .product(
                    name: "AsyncAlgorithms",
                    package: "swift-async-algorithms"
                )
            ]
        ),
        // Image snapshots. They run only from scripts/snapshot.sh, on a pinned simulator.
        .testTarget(
            name: "CloudDriveSnapshotTests",
            dependencies: [
                "CloudDrive",
                "MEGADesignToken",
                "MEGAL10n",
                .product(name: "MEGASnapshot", package: "MEGASnapshot")
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
