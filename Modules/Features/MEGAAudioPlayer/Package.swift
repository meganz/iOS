// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MEGAAudioPlayer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGAAudioPlayer",
            targets: ["MEGAAudioPlayer"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../MEGASharedRepo/MEGAInfrastructure"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGAAudioPlayer",
            dependencies: [
                "MEGADomain",
                "MEGAAssets",
                "MEGAL10n",
                "MEGASwiftUI",
                "MEGAInfrastructure",
                "MEGADesignToken"
            ]
        ),
        .testTarget(
            name: "MEGAAudioPlayerTests",
            dependencies: ["MEGAAudioPlayer"]
        )
    ]
)
