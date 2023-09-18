import Foundation
import PackagePlugin

@main
struct TokenCodegenPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let inputFiles = target.sourceFiles(withSuffix: ".json").filter { file in
            file.path.string.contains("/Resources")
        }

        // We're only doing this for core colors now
        guard let colorsInput = inputFiles.first(where: { $0.path.string.contains("core") })?.path else {
            Diagnostics.warning("No core.json found for core colors under /Resources, return")
            return []
        }

        let executablePath = try context.tool(named: "TokenCodegenGenerator").path

        let output = context.pluginWorkDirectory.appending(["MEGADesignSystemColors.swift"])

        return [
            .buildCommand(
                displayName: "Generating Color design tokens",
                executable: executablePath,
                arguments: [colorsInput, output],
                inputFiles: [colorsInput],
                outputFiles: [output]
            )
        ]
    }
}
