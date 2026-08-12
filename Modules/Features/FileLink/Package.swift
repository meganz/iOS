// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FileLink",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FileLink",
            targets: ["FileLink"]
        )
    ],
    dependencies: [
        // UI
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../MEGASharedRepo/MEGAUIComponent"),

        // Presentation
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Presentation/MEGAAssets"),

        // Domain
        .package(path: "../../Domain/MEGADomain"),

        // Repository
        .package(path: "../../Repository/MEGAAppSDKRepo"),

        // DataSource
        .package(path: "../../DataSource/MEGASDK"),

        // Infra
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../MEGASharedRepo/MEGATest")
    ],
    targets: [
        .target(
            name: "FileLink",
            dependencies: [
                "MEGASwiftUI",
                "MEGAUIComponent",
                "MEGAL10n",
                "MEGAAppPresentation",
                "MEGAAssets",
                "MEGADomain",
                "MEGAAppSDKRepo",
                .product(name: "MEGASdk", package: "MEGASDK"),
                "MEGASwift",
                "MEGADesignToken"
            ]
        ),
        .testTarget(
            name: "FileLinkTests",
            dependencies: [
                "FileLink",
                "MEGATest",
                "MEGAL10n",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                .product(name: "MEGAAppSDKRepoMock", package: "MEGAAppSDKRepo"),
                .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation")
            ]
        )
    ]
)
