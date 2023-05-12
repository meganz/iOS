// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v10_13)],
    dependencies: [
         .package(url: "https://github.com/Realm/SwiftLint", from: "0.52.1")
    ],
    targets: [.target(name: "BuildTools", path: "")]
)
