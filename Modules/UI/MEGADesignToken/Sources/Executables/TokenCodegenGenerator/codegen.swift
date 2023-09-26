import SwiftSyntax
import SwiftSyntaxBuilder

struct CodegenInput {
    let dark: SemanticInput
    let light: SemanticInput
}

enum SemanticInput {
    case dark(ColorData)
    case light(ColorData)

    var data: ColorData {
        switch self {
        case .dark(let data), .light(let data):
            return data
        }
    }

    var identifier: String {
        switch self {
        case .dark:
            return "MEGADesignTokenDarkColors"
        case .light:
            return "MEGADesignTokenLightColors"
        }
    }
}

enum CodegenError: Error {
    case codeHasWarnings
    case codeHasErrors
}

func generateCode(from input: CodegenInput) throws -> String {
    let code = generateSourceFileSyntax(from: input)

    guard !code.hasWarning else {
        throw CodegenError.codeHasWarnings
    }

    guard !code.hasError else {
        throw CodegenError.codeHasErrors
    }

    return code.description
}

private func generateSourceFileSyntax(from input: CodegenInput) -> SourceFileSyntax {
    SourceFileSyntax {
        generateImport()
        generateTopLevelEnum(with: input.dark)
        generateTopLevelEnum(with: input.light)
    }
}

private func generateImport() -> ImportDeclSyntax {
    let importPath = ImportPathComponentListSyntax {
        .init(leadingTrivia: .space, name: .identifier("UIKit"), trailingTrivia: .newline)
    }

    return ImportDeclSyntax(importKeyword: .keyword(.import), path: importPath)
}

private func generateTopLevelEnum(with input: SemanticInput) -> EnumDeclSyntax {
    let memberBlockBuilder = {
        MemberBlockItemListSyntax {
            for (enumName, category) in input.data {
                generateEnum(for: enumName, category: category)
            }
        }
    }

    return EnumDeclSyntax(
        leadingTrivia: .newline,
        modifiers: [.init(name: .keyword(.public, trailingTrivia: .space))],
        name: .identifier(input.identifier, leadingTrivia: .space, trailingTrivia: .space),
        memberBlockBuilder: memberBlockBuilder,
        trailingTrivia: .newline
    )
}

private func generateEnum(for name: String, category: ColorCategory) -> EnumDeclSyntax {
    let memberBlock = MemberBlockSyntax {
        switch category {
        case .leaf(let colorInfoDict):
            for colorName in colorInfoDict.keys {
                generateVariable(for: colorName, with: colorInfoDict[colorName]!)
            }
        case .node(let subCategories):
            for (subEnumName, subCategory) in subCategories {
                generateEnum(for: subEnumName, category: subCategory)
            }
        }
    }

    return EnumDeclSyntax(
        leadingTrivia: .newlines(2),
        modifiers: [.init(name: .keyword(.public, trailingTrivia: .space))],
        name: .identifier(name.toPascalCase(), leadingTrivia: .space, trailingTrivia: .space),
        memberBlock: memberBlock
    )
}

private func generateVariable(for name: String, with info: ColorInfo) -> DeclSyntax {
    guard let rbga = info.rgba else {
        print("Codegen: unable to parse Color(\(name))")
        return DeclSyntax("")
    }

    let variableName = sanitizeVariableName(name)

    return DeclSyntax(
    """
    \n
    public static let \(raw: variableName) = UIColor(red: \(raw: rbga.red), green: \(raw: rbga.green), blue: \(raw: rbga.blue), alpha: \(raw: rbga.alpha))
    \n
    """
    )
}

private func sanitizeVariableName(_ name: String) -> String {
    name
        .deletingPrefix("--color-")
        .replacingOccurrences(of: "-", with: " ")
        .toCamelCase()
}
