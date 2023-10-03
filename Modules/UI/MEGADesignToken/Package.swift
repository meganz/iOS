// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MEGADesignToken",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MEGADesignToken",
            targets: ["MEGADesignToken"]
        ),
        .plugin(
            name: "TokenCodegen",
            targets: ["TokenCodegen"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", exact: "509.0.0")
    ],
    targets: [
        .target(
            name: "MEGADesignToken",
            plugins: ["TokenCodegen"]
        ),
        .plugin(
            name: "TokenCodegen",
            capability: .buildTool(),
            dependencies: ["TokenCodegenGenerator"]
        ),
        .executableTarget(
            name: "TokenCodegenGenerator",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ],
            path: "Sources/Executables/TokenCodegenGenerator"
        ),
        .testTarget(
            name: "MEGADesignTokenTests",
            dependencies: ["MEGADesignToken", "TokenCodegenGenerator"]
        )
    ]
)
