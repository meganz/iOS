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
        // UI
        .package(path: "../../UI/MEGASwiftUI"),
        
        // Presentation
        .package(path: "../../Presentation/MEGAL10n"),
        
        // Domain
        .package(path: "../../Domain/MEGADomain"),
        
        // Repository
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        
        // DataSource
        .package(path: "../../DataSource/MEGASDK"),
        
        // Infra
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "FolderLink",
            dependencies: [
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
                .product(name: "MEGAAppSDKRepoMock", package: "MEGAAppSDKRepo")
            ]
        )
    ]
)
