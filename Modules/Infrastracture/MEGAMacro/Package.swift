// swift-tools-version: 5.10

import CompilerPluginSupport
import PackageDescription

let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency=targeted")
]

let package = Package(
    name: "MEGAMacro",
    platforms: [.macOS(.v10_15), .iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MEGAMacro",
            targets: ["MEGAMacro"]
        ),
        .executable(
            name: "MEGAMacroClient",
            targets: ["MEGAMacroClient"]
        )
    ],
    dependencies: [
        // Depend on the Swift 5.9 release of SwiftSyntax
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "509.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "MEGAMacroMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            swiftSettings: settings
        ),
        
        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "MEGAMacro", dependencies: ["MEGAMacroMacros"]),
        
        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "MEGAMacroClient", dependencies: ["MEGAMacro"]),
        
        // A test target used to develop the macro implementation.
        .testTarget(
            name: "MEGAMacroTests",
            dependencies: [
                "MEGAMacroMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            swiftSettings: settings
        )
    ]
)
