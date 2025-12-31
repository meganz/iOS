// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FolderLink",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FolderLink",
            targets: ["FolderLink"]
        ),
    ],
    dependencies: [
        .package(path: "../../Presentation/MEGAL10n"),
        .package(url: "https://github.com/meganz/MEGADesignToken.git", branch: "main")
    ],
    targets: [
        .target(
            name: "FolderLink",
            dependencies: [
                "MEGAL10n",
                "MEGADesignToken"
            ]
        ),
        .testTarget(
            name: "FolderLinkTests",
            dependencies: ["FolderLink"]
        ),
    ]
)
