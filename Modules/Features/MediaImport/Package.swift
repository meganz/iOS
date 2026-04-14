// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MediaImport",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "MediaImport", targets: ["MediaImport"])
    ],
    dependencies: [
        .package(path: "../../MEGASharedRepo/MEGASwift"),
        .package(path: "../../Presentation/MEGAL10n"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MediaImport",
            dependencies: ["MEGASwift", "MEGAL10n", "MEGADesignToken"]
        )
    ]
)
