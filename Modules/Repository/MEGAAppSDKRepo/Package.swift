// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGAAppSDKRepo",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MEGAAppSDKRepo",
            targets: ["MEGAAppSDKRepo"]),
        .library(
            name: "MEGAAppSDKRepoMock",
            targets: ["MEGAAppSDKRepoMock"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Domain/MEGAAnalyticsDomain"),
        .package(path: "../../DataSource/MEGASdk"),
        .package(path: "../../MEGASharedRepo/MEGAInfrastructure"),
        .package(path: "../../MEGASharedRepo/MEGASDKRepo"),
        .package(path: "../../MEGASharedRepo/MEGATest"),
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../MEGARepo"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "MEGAAppSDKRepo",
            dependencies: [
                "MEGAAnalyticsDomain",
                "MEGADomain",
                "MEGASdk",
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAppDistribution-Beta", package: "firebase-ios-sdk"),
                .product(name: "MEGAInfrastructure", package: "MEGAInfrastructure"),
                .product(name: "MEGASDKRepo", package: "MEGASDKRepo"),
                "MEGASwift",
                "MEGARepo"
            ],
            cxxSettings: [
                .define("ENABLE_CHAT")
            ],
            swiftSettings: settings),
        .target(
            name: "MEGAAppSDKRepoMock",
            dependencies: [
                "MEGAAppSDKRepo",
                .product(name: "MEGASDKRepo", package: "MEGASDKRepo")
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGAAppSDKRepoTests",
            dependencies: [
                "MEGAAppSDKRepo",
                "MEGAAppSDKRepoMock",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                "MEGATest"
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
