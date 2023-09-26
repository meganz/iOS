import Foundation
import PackagePlugin

@main
struct TokenCodegenPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let inputFiles = target.sourceFiles(withSuffix: ".json").filter { file in
            file.path.string.contains("/Resources")
        }

        let inputPaths = inputFiles.map(\.path)

        let executablePath = try context.tool(named: "TokenCodegenGenerator").path

        let output = context.pluginWorkDirectory.appending(["MEGADesignTokenColors.swift"])

        return [
            .buildCommand(
                displayName: "Generating Color design tokens",
                executable: executablePath,
                arguments: [inputPaths, output],
                inputFiles: inputPaths,
                outputFiles: [output]
            )
        ]
    }
}
