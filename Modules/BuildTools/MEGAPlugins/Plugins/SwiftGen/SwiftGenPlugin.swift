import Foundation
import PackagePlugin

@main
struct SwiftGenPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let configuration = context.package.directory.appending("SwiftGen/swiftgen.yml")

        return [
            .prebuildCommand(
                displayName: "Running SwiftGen for \(target.name)",
                executable: try context.tool(named: "swiftgen").path,
                arguments: [
                    "config",
                    "run",
                    "--config",
                    "\(configuration)"
                ],
                environment: [
                    "PROJECT_DIR": context.package.directory,
                    "TARGET_NAME": target.name,
                    "DERIVED_SOURCES_DIR": context.pluginWorkDirectory
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftGenPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let configuration = context.xcodeProject.directory.appending("SwiftGen/swiftgen.yml")

        return [
            .prebuildCommand(
                displayName: "Running SwiftGen for \(target.displayName)",
                executable: try context.tool(named: "swiftgen").path,
                arguments: [
                    "config",
                    "run",
                    "--config",
                    "\(configuration)"
                ],
                environment: [
                    "PROJECT_DIR": context.xcodeProject.directory,
                    "TARGET_NAME": target.displayName,
                    "DERIVED_SOURCES_DIR": context.pluginWorkDirectory
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}
#endif
