// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FolderLink",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FolderLink",
            targets: ["FolderLink"]
        )
    ],
    dependencies: [
        // Features
        .package(path: "../Search"),
        
        // UI
        .package(path: "../../UI/MEGASwiftUI"),
        
        // Presentation
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        
        // Domain
        .package(path: "../../Domain/MEGADomain"),
        
        // Repository
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        
        // DataSource
        .package(path: "../../DataSource/MEGASDK"),
        
        // Infra
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(path: "../../MEGASharedRepo/MEGATest")
    ],
    targets: [
        .target(
            name: "FolderLink",
            dependencies: [
                "Search",
                "MEGASwiftUI",
                "MEGAL10n",
                "MEGADomain",
                "MEGAAppSDKRepo",
                .product(name: "MEGASdk", package: "MEGASDK"),
                "MEGADesignToken"
            ]
        ),
        .testTarget(
            name: "FolderLinkTests",
            dependencies: [
                "FolderLink",
                "MEGATest",
                .product(name: "MEGAAppSDKRepoMock", package: "MEGAAppSDKRepo"),
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                .product(name: "MEGAAppPresentationMock", package: "MEGAAppPresentation")
            ]
        )
    ]
)
