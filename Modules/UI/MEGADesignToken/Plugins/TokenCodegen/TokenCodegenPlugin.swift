import Foundation
import PackagePlugin

@main
struct TokenCodegenPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let logName = "TokenCodegenPlugin(BuildToolPlugin)"

        guard let target = target as? SourceModuleTarget else {
            Diagnostics.error("\(logName): unable to cast target as SourceModuleTarget")
            return []
        }

        let inputFiles = target.sourceFiles(withSuffix: Constants.resourcesExtension).filter { file in
            file.path.string.contains(Constants.resourcesPath)
        }

        let inputPaths = inputFiles.map(\.path)

        guard !inputPaths.isEmpty else {
            let message = emptyResourcesMessage(for: logName)
            Diagnostics.error(message)
            return []
        }

        let executablePath = try context.tool(named: Constants.executable).path

        let output = context.pluginWorkDirectory.appending([Constants.outputSuffix])

        return [
            .buildCommand(
                displayName: Constants.displayName,
                executable: executablePath,
                arguments: [inputPaths, output],
                inputFiles: inputPaths,
                outputFiles: [output]
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension TokenCodegenPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let logName = "TokenCodegenPlugin(XcodeBuildToolPlugin)"

        let inputFiles = target.inputFiles.filter { file in
            file.path.string.hasSuffix(Constants.resourcesExtension) && file.path.string.contains(Constants.resourcesPath)
        }

        let inputPaths = inputFiles.map(\.path)

        guard !inputPaths.isEmpty else {
            let message = emptyResourcesMessage(for: logName)
            Diagnostics.error(message)
            return []
        }

        let executablePath = try context.tool(named: Constants.executable).path

        let output = context.pluginWorkDirectory.appending([Constants.outputSuffix])

        return [
            .buildCommand(
                displayName: Constants.displayName,
                executable: executablePath,
                arguments: [inputPaths, output],
                inputFiles: inputPaths,
                outputFiles: [output]
            )
        ]
    }
}
#endif

// MARK: - Constants

private extension TokenCodegenPlugin {
    enum Constants {
        static let resourcesExtension = ".json"
        static let resourcesPath = "/MEGADesignTokenResources"
        static let executable = "TokenCodegenGenerator"
        static let outputSuffix = "MEGADesignTokenColors.swift"
        static let displayName = "Generating code for Design Tokens"
    }
}

// MARK: - Helpers

private extension TokenCodegenPlugin {
    func emptyResourcesMessage(for logName: String) -> String {
        "\(logName): unable to find \(Constants.resourcesExtension) files under \(Constants.resourcesPath)"
    }
}
