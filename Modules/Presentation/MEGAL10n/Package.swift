// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MEGAL10n",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAL10n",
            targets: ["MEGAL10n"]
        ),
        .library(
            name: "MEGAL10nObjc",
            targets: ["MEGAL10nObjc"]
        )
    ],
    dependencies: [
        .package(path: "../../BuildTools/MEGAPlugins")
    ],
    targets: [
        .target(
            name: "MEGAL10n",
            exclude: [
                "Localization.h",
                "Localization.m"
            ],
            plugins: [
                .plugin(name: "SwiftGen", package: "MEGAPlugins")
            ]
        ),
        .target(
            name: "MEGAL10nObjc",
            path: "Sources/MEGAL10n",
            exclude: [
                "Localization.swift"
            ],
            publicHeadersPath: "."
        )
    ]
)
