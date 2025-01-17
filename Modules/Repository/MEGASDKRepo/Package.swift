// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "MEGASDKRepo",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGASDKRepo",
            targets: ["MEGASDKRepo"]),
        .library(
            name: "MEGASDKRepoMock",
            targets: ["MEGASDKRepoMock"])
    ],
    dependencies: [
        .package(path: "../../Domain/MEGADomain"),
        .package(path: "../../Domain/MEGAAnalyticsDomain"),
        .package(path: "../../DataSource/MEGASdk"),
        .package(path: "../../Infrastracture/MEGATest"),
        .package(path: "../../Infrastracture/MEGAMacro"),
        .package(url: "https://github.com/meganz/SAMKeychain.git", from: "2.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(path: "../../Repository/MEGARepo")
    ],
    targets: [
        .target(
            name: "MEGASDKRepo",
            dependencies: [
                "MEGAAnalyticsDomain",
                "MEGADomain",
                "MEGASdk",
                "MEGAMacro",
                "SAMKeychain",
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAppDistribution-Beta", package: "firebase-ios-sdk"),
                "MEGARepo"
            ],
            cxxSettings: [
                .define("ENABLE_CHAT")
            ],
            swiftSettings: settings),
        .target(
            name: "MEGASDKRepoMock",
            dependencies: ["MEGASDKRepo"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "MEGASDKRepoTests",
            dependencies: [
                "MEGASDKRepo",
                "MEGASDKRepoMock",
                .product(name: "MEGADomainMock", package: "MEGADomain"),
                "MEGATest"
            ],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
