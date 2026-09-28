// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ViewedLinks",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ViewedLinks",
            targets: ["ViewedLinks"]
        ),
        .library(
            name: "ViewedLinksMock",
            targets: ["ViewedLinksMock"]
        )
    ],
    dependencies: [
        // Features
        .package(path: "../Search"),

        // UI
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../UI/MEGAUIKit"),
        .package(path: "../../MEGASharedRepo/MEGAUIComponent"),

        // Presentation
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),

        // Domain
        .package(path: "../../Domain/MEGADomain"),

        // Infrastructure
        .package(path: "../../MEGASharedRepo/MEGASwift"),

        // Repository
        .package(path: "../../Repository/MEGAAppSDKRepo"),

        // DataSource
        .package(path: "../../DataSource/MEGASDK"),

        // Test
        .package(path: "../../MEGASharedRepo/MEGATest")
    ],
    targets: [
        .target(
            name: "ViewedLinks",
            dependencies: [
                "Search",
                "MEGADesignToken",
                "MEGASwiftUI",
                "MEGAUIKit",
                "MEGAUIComponent",
                "MEGAAppPresentation",
                "MEGAAssets",
                "MEGAL10n",
                "MEGADomain",
                "MEGAAppSDKRepo",
                .product(name: "MEGASdk", package: "MEGASDK"),
                "MEGASwift"
            ]
        ),
        .target(
            name: "ViewedLinksMock",
            dependencies: [
                "ViewedLinks",
                "MEGASwift"
            ]
        ),
        .testTarget(
            name: "ViewedLinksTests",
            dependencies: [
                "ViewedLinks",
                "ViewedLinksMock",
                "Search",
                "MEGAAssets",
                "MEGADomain",
                "MEGAL10n",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                "MEGASwift",
                "MEGATest"
            ]
        )
    ]
)
