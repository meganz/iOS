// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MEGAPlugins",
    platforms: [
        .macOS(.v10_15), .iOS(.v14)
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
            url: "https://github.com/realm/SwiftLint/releases/download/0.52.2/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "89651e1c87fb62faf076ef785a5b1af7f43570b2b74c6773526e0d5114e0578e"
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
