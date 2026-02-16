// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Favourites",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Favourites",
            targets: ["Favourites"]
        )
    ],
    dependencies: [
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../Search"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Favourites",
            dependencies: [
                "MEGASwiftUI",
                "MEGADesignToken",
                "MEGAAssets",
                "MEGADomain",
                "MEGAL10n",
                "MEGASwift",
                "Search",
                "MEGAAppPresentation",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ]
        ),
        .testTarget(
            name: "FavouritesTests",
            dependencies: ["Favourites"]
        )
    ]
)
