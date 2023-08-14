import Foundation
import PackagePlugin

@main
struct SwiftLintPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let swiftFiles = fetchModifiedSwiftFiles()

        guard !swiftFiles.isEmpty else {
            Diagnostics.remark("No new or modified .swift files, return")
            return []
        }

        return [
            .buildCommand(
                displayName: "Running SwiftLint for \(target.name)",
                executable: try context.tool(named: "swiftlint").path,
                arguments: [
                    "lint",
                    "--strict",
                    "--config",
                    "\(context.package.directory.string)/.swiftlint.yml",
                    "--cache-path",
                    "\(context.pluginWorkDirectory.string)/cache"
                ] + swiftFiles,
                environment: [:]
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftLintPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let swiftFiles = fetchModifiedSwiftFiles()

        guard !swiftFiles.isEmpty else {
            Diagnostics.remark("No new or modified .swift files, return")
            return []
        }

        return [
            .buildCommand(
                displayName: "Running SwiftLint for \(target.displayName)",
                executable: try context.tool(named: "swiftlint").path,
                arguments: [
                    "lint",
                    "--strict",
                    "--config",
                    "\(context.xcodeProject.directory.string)/.swiftlint.yml",
                    "--cache-path",
                    "\(context.pluginWorkDirectory.string)/cache"
                ] + swiftFiles,
                environment: [:]
            )
        ]
    }
}
#endif

// MARK: - Helper methods
extension SwiftLintPlugin {
    /// Fetches newly added or modified `.swift` files so the `swiftlint` plugin only run on those instead of the whole project
    func fetchModifiedSwiftFiles() -> [String] {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["git", "diff", "--diff-filter=AM", "--name-only"]

        let outputPipe = Pipe()
        process.standardOutput =  outputPipe
        process.launch()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

        guard let outputString = String(data: outputData, encoding: .utf8) else {
            return []
        }

        let changedFiles = outputString
            .split(separator: "\n")
            .compactMap { String($0) }

        return changedFiles.filter { $0.hasSuffix(".swift") }
    }
}
