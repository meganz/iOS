// swift-tools-version: 5.9

import PackageDescription

let settings: [SwiftSetting] = [.enableExperimentalFeature("ExistentialAny"), .enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "PhotosBrowser",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PhotosBrowser",
            targets: ["PhotosBrowser"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PhotosBrowser",
            swiftSettings: settings),
        .testTarget(
            name: "PhotosBrowserTests",
            dependencies: ["PhotosBrowser"],
            swiftSettings: settings)
    ]
)
