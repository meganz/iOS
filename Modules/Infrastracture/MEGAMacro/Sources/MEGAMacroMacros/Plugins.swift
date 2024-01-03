#if canImport(SwiftCompilerPlugin)

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MEGAMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        NewRepoMacro.self,
    ]
}
#endif
