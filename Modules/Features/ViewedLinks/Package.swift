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
        .package(path: "../../UI/MEGASwiftUI"),
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

        // Test
        .package(path: "../../MEGASharedRepo/MEGATest")
    ],
    targets: [
        .target(
            name: "ViewedLinks",
            dependencies: [
                "Search",
                "MEGASwiftUI",
                "MEGAUIComponent",
                "MEGAAppPresentation",
                "MEGAAssets",
                "MEGAL10n",
                "MEGADomain",
                "MEGAAppSDKRepo",
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
                "MEGADomain",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                "MEGATest"
            ]
        )
    ]
)
