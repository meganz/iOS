// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAAppPresentation",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGAAppPresentation",
            targets: ["MEGAAppPresentation"]
        ),
        .library(
            name: "MEGAAppPresentationMock",
            targets: ["MEGAAppPresentationMock"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Domain/MEGAAnalyticsDomain"),
        .package(path: "../../Repository/MEGAAppSDKRepo"),
        .package(path: "../../Infrastracture/MEGATest"),
        .package(url: "https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MEGAAppPresentation",
            dependencies: [
                "MEGAAnalyticsDomain",
                "MEGADomain",
                "MEGAAppSDKRepo",
                .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")
            ],
            swiftSettings: settings),
        .target(
            name: "MEGAAppPresentationMock",
            dependencies: ["MEGAAppPresentation", 
                            .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios")
            ],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAAppPresentationTests",
            dependencies: ["MEGAAppPresentation",
                           "MEGAAppPresentationMock",
                           "MEGATest",
                           "MEGAAnalyticsDomain",
                           "MEGADomain",
                           "MEGAAppSDKRepo",
                           .product(name: "MEGAAnalyticsiOS", package: "mobile-analytics-ios"),
                           .product(name: "MEGADomainMock", package: "MEGADomain")
                          ],
            swiftSettings: settings)
    ],
    swiftLanguageModes: [.v6]
)
