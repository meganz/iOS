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
        .package(path: "../Transfer"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../Favourites"),
        .package(path: "../Search"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../MEGASharedRepo/MEGAPreference"),
        .package(path: "../../MEGASharedRepo/MEGAConnectivity"),
        .package(path: "../Shared/ContentLibraries"),
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main")
    ],
    targets: [
        .target(
            name: "Home",
            dependencies: [
                "MEGASwiftUI",
                "Transfer",
                "MEGADesignToken",
                "MEGAAssets",
                "MEGAL10n",
                "Favourites",
                "Search",
                "MEGAAppPresentation",
                "MEGADomain",
                "MEGAAppSDKRepo",
                "MEGAPreference",
                "MEGAConnectivity",
                "ContentLibraries",
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")
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
