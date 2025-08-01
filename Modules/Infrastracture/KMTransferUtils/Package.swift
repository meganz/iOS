// swift-tools-version: 6.0

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]),
                                .enableExperimentalFeature("ExistentialAny")]

let package = Package(
    name: "KMTransferUtils",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "KMTransferUtils",
            targets: ["KMTransferUtils"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "KMTransferUtils",
            path: "Frameworks/KMTransferUtils.xcframework"
        )
    ],
    swiftLanguageModes: [.v6]
)
