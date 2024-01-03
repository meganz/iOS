import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct NewRepoMacro: MemberMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        var typeName = ""
        var sdkInstance: String
        
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
        } else if let structDecl = declaration.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
        } else {
            throw CustomError.message("@newRepo requires a class or struct declaration")
        }
        
        guard case .argumentList(let arguments) = node.arguments, arguments.count == 1,
              let memberAccessExn = arguments.first?.expression.as(MemberAccessExprSyntax.self),
              let sdkType = memberAccessExn.base?.as(DeclReferenceExprSyntax.self),
              let sharedVariable = memberAccessExn.declName.as(DeclReferenceExprSyntax.self)?.baseName.text else {
            throw CustomError.message(#"@newRepo requires SDK instance as an argument, in the form "MEGASDK.shared"."#)
        }
        
        sdkInstance = "\(sdkType).\(sharedVariable)"
        
        let result: DeclSyntax =
        """
        public static var newRepo: \(raw: typeName) {
            \(raw: typeName)(sdk:\(raw: sdkInstance))
        }
        
        private let sdk: \(raw: sdkType)
        
        public init(sdk:\(raw: sdkType)) { self.sdk = sdk }
        """
        
        return [result]
    }
}

extension NewRepoMacro: ExtensionMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard declaration.as(ClassDeclSyntax.self) != nil || declaration.as(StructDeclSyntax.self) != nil else {
            return []
        }
        
        guard case .argumentList(let arguments) = node.arguments,
              arguments.count == 1 else { return [] }
        
        let repositoryExtension = try ExtensionDeclSyntax("extension \(type.trimmed): RepositoryProtocol {}")
        
        return [repositoryExtension]
    }
}
