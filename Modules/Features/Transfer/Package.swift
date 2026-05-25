// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Transfer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Transfer",
            targets: ["Transfer"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../MEGASharedRepo/MEGAPreference"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Repository/MEGARepo"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "Transfer",
            dependencies: [
                "MEGAAppSDKRepo",
                "MEGADomain",
                "MEGAL10n",
                "MEGAPreference",
                "MEGAAssets",
                "MEGARepo",
                "MEGADesignToken"
            ]
        ),
        .testTarget(
            name: "TransferTests",
            dependencies: ["Transfer", "MEGADomain"]
        )
    ]
)
