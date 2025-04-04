#if canImport(SwiftCompilerPlugin)

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MEGAMacroPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        NewRepoMacro.self,
    ]
}
#endif
