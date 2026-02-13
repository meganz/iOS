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
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
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
                "Search"
            ]
        ),
        .testTarget(
            name: "FavouritesTests",
            dependencies: ["Favourites"]
        )
    ]
)
