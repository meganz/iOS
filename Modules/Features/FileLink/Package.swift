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

        // Presentation
        .package(path: "../../Presentation/MEGAL10n"),

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
                "MEGAL10n",
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
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                .product(name: "MEGAAppSDKRepoMock", package: "MEGAAppSDKRepo")
            ]
        )
    ]
)
