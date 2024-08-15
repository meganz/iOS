// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MEGAPlugins",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .plugin(
            name: "SwiftGen",
            targets: ["SwiftGen"]
        ),
        .plugin(
            name: "SwiftLint",
            targets: ["SwiftLint"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "SwiftGenBinary",
            url: "https://github.com/SwiftGen/SwiftGen/releases/download/6.6.2/swiftgen-6.6.2.artifactbundle.zip",
            checksum: "7586363e24edcf18c2da3ef90f379e9559c1453f48ef5e8fbc0b818fbbc3a045"
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.54.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "963121d6babf2bf5fd66a21ac9297e86d855cbc9d28322790646b88dceca00f1"
        ),
        .plugin(
            name: "SwiftGen",
            capability: .buildTool(),
            dependencies: ["SwiftGenBinary"]
        ),
        .plugin(
            name: "SwiftLint",
            capability: .buildTool(),
            dependencies: ["SwiftLintBinary"]
        )
    ]
)
