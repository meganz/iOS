// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Notifications",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "Notifications",
            targets: ["Notifications"])
    ],
    dependencies: [
        .package(path: "../../../Localization/MEGAL10n"),
        .package(path: "../../MEGAPresentation"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main")
    ],
    targets: [
        .target(
            name: "Notifications",
            dependencies: [
                "MEGAL10n",
                "MEGAPresentation",
                "MEGASwiftUI",
                "MEGADesignToken"
            ]
        )
    ]
)
