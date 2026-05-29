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
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Repository/MEGARepo"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../UI/MEGAUIKit"),
        .package(path: "../../MEGASharedRepo/MEGAUIComponent"),
        .package(path: "../Search"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Transfer",
            dependencies: [
                "MEGAAppSDKRepo",
                "MEGADomain",
                "MEGAL10n",
                "MEGAPreference",
                "MEGASwift",
                "MEGAAssets",
                "MEGAAppPresentation",
                "MEGARepo",
                "MEGASwiftUI",
                "MEGAUIKit",
                "MEGAUIComponent",
                "Search",
                "MEGADesignToken",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ]
        ),
        .testTarget(
            name: "TransferTests",
            dependencies: [
                "Transfer",
                "MEGADomain",
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ]
        )
    ]
)
