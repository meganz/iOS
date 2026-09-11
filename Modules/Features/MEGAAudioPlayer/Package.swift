// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MEGAAudioPlayer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MEGAAudioPlayer",
            targets: ["MEGAAudioPlayer"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../MEGASharedRepo/MEGAUIComponent"),
        .package(path: "../../Presentation/MEGAAssets"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(path: "../../UI/MEGASwiftUI"),
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../Presentation/MEGAAppPresentation"),
        .package(path: "../../Infrastracture/MEGAFoundation"),
        .package(path: "../../MEGASharedRepo/MEGAInfrastructure"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main"),
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGAAudioPlayer",
            dependencies: [
                "MEGADomain",
                "MEGASwift",
                "MEGAAssets",
                "MEGAL10n",
                "MEGAAppSDKRepo",
                "MEGASwiftUI",
                "MEGAFoundation",
                "MEGAInfrastructure",
                "MEGADesignToken",
                "MEGAUIComponent",
                .product(name: "MEGAAppPresentation", package: "MEGAAppPresentation"),
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")
            ]
        ),
        .testTarget(
            name: "MEGAAudioPlayerTests",
            dependencies: [
                "MEGAAudioPlayer",
                .product(name: "MEGADomainMock", package: "MEGADomain")
            ]
        )
    ]
)
