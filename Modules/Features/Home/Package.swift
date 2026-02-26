// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Home",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Home",
            targets: ["Home"]
        )
    ],
    dependencies: [
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../Favourites"),
        .package(path: "../Search"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Repository/MEGAAppSDKRepo")
    ],
    targets: [
        .target(
            name: "Home",
            dependencies: [
                "MEGASwiftUI",
                "MEGADesignToken",
                "MEGAAssets",
                "MEGAL10n",
                "Favourites",
                "Search",
                "MEGAAppPresentation",
                "MEGADomain",
                "MEGAAppSDKRepo"
                ]
        ),
        .testTarget(
            name: "HomeTests",
            dependencies: [
                "Home",
                .product(name: "MEGAAppSDKRepoMock", package: "MEGAAppSDKRepo"),
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ]
        )
    ]
)
