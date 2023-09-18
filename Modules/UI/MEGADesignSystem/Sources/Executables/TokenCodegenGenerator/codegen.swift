import SwiftSyntax
import SwiftSyntaxBuilder

enum CodegenError: Error {
    case codeHasWarnings
    case codeHasErrors
}

func generateCode(from data: ColorData) throws -> String {
    let code = generateSourceFileSyntax(from: data)

    guard !code.hasWarning else {
        throw CodegenError.codeHasWarnings
    }

    guard !code.hasError else {
        throw CodegenError.codeHasErrors
    }

    return code.description
}

private func generateSourceFileSyntax(from data: ColorData) -> SourceFileSyntax {
    SourceFileSyntax {
        generateImport()
        generateTopLevelEnum(from: data)
    }
}

private func generateImport() -> ImportDeclSyntax {
    let importPath = ImportPathComponentListSyntax {
        .init(leadingTrivia: .space, name: .identifier("UIKit"), trailingTrivia: .newline)
    }

    return ImportDeclSyntax(importKeyword: .keyword(.import), path: importPath, trailingTrivia: .newline)
}

private func generateTopLevelEnum(from data: ColorData) -> EnumDeclSyntax {
    let memberBlockBuilder = {
        MemberBlockItemListSyntax {
            for (enumName, category) in data {
                generateEnum(for: enumName, category: category)
            }
        }
    }

    return EnumDeclSyntax(
        name: .identifier("MEGADesignSystemColors", leadingTrivia: .space, trailingTrivia: .space),
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
        name: .identifier(name.toPascalCase(), leadingTrivia: .space, trailingTrivia: .space),
        memberBlock: memberBlock
    )
}

private func generateVariable(for name: String, with info: ColorInfo) -> DeclSyntax {
    guard let rbga = info.rgba else {
        print("Codegen: unable to parse Color(\(name))")
        return DeclSyntax("")
    }

    // Prefix with '_' if name is numeric, cause Swift doesn't allow only numeric variable identifiers
    let variableName = name.isNumeric ? "_" + name : name

    return DeclSyntax(
    """
    \n
    static let \(raw: variableName) = UIColor(red: \(raw: rbga.red), green: \(raw: rbga.green), blue: \(raw: rbga.blue), alpha: \(raw: rbga.alpha))
    \n
    """
    )
}
