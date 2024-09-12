// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Search",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "Search",
            targets: ["Search"]
        ),
        .library(
            name: "SearchMock",
            targets: ["SearchMock"]
        )
        
    ],
    dependencies: [
        .package(path: "../../../Infrastructure/MEGASwift"),
        .package(path: "../../../Infrastructure/MEGAFoundation"),
        .package(path: "../../../Localization/MEGAL10n"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../../UI/MEGAUIKit"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.1.0"),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.12.0"
        ),
        .package(url: "https://github.com/meganz/MEGADesignToken", branch: "main"),
        .package(path: "../../../Infrastracture/MEGATest"),
    ],
    targets: [
        .target(
            name: "Search",
            dependencies: [
                "MEGASwiftUI",
                "MEGAL10n",
                "MEGASwift",
                "MEGADesignToken",
                "MEGAFoundation"
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "SearchMock",
            dependencies: ["Search"],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "SearchTests",
            dependencies: [
                "Search", 
                "SearchMock",
                "MEGAUIKit",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
                "MEGATest"
            ],
            resources: [
                .process("folder.png"),
                .process("scenery.png")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        )
    ]
)
