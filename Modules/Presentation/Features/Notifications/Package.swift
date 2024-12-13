// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

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
            ],
            swiftSettings: settings
        ),
        .target(
            name: "NotificationsMocks",
            dependencies: ["Notifications"]
        ),
        .testTarget(
            name: "NotificationsTests",
            dependencies: [
                "Notifications",
                "NotificationsMocks",
                "MEGAL10n",
                "MEGASwiftUI",
                .product(name: "MEGASwiftUIMock", package: "MEGASwiftUI")
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
