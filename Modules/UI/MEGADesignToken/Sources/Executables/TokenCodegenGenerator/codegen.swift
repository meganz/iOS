import SwiftSyntax
import SwiftSyntaxBuilder

struct CodegenInput {
    let dark: SemanticInput
    let light: SemanticInput
    let spacing: NumberInput
    let radius: NumberInput
}

enum NumberInput {
    case radius(NumberData)
    case spacing(NumberData)

    var data: NumberData {
        switch self {
        case .radius(let data), .spacing(let data):
            return data
        }
    }

    var identifier: String {
        switch self {
        case .radius:
            return "MEGADesignTokenRadius"
        case .spacing:
            return "MEGADesignTokenSpacing"
        }
    }
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
    case inputIsWrong(reason: String)
}

func generateCode(with input: CodegenInput) throws -> String {
    let code = try generateSourceFileSyntax(from: input)

    guard !code.hasWarning else {
        throw CodegenError.codeHasWarnings
    }

    guard !code.hasError else {
        throw CodegenError.codeHasErrors
    }

    return code.description
}

private func generateSourceFileSyntax(from input: CodegenInput) throws -> SourceFileSyntax {
    try SourceFileSyntax {
        generateImport()
        try generateSemanticTopLevelEnum(with: input.dark)
        try generateSemanticTopLevelEnum(with: input.light)
        generateNumberTopLevelEnum(with: input.spacing)
        generateNumberTopLevelEnum(with: input.radius)
    }
}

private func generateImport() -> ImportDeclSyntax {
    let importPath = ImportPathComponentListSyntax {
        .init(leadingTrivia: .space, name: .identifier("UIKit"), trailingTrivia: .newline)
    }

    return ImportDeclSyntax(importKeyword: .keyword(.import), path: importPath)
}

private func generateSemanticTopLevelEnum(with input: SemanticInput) throws -> EnumDeclSyntax {
    let memberBlockBuilder = {
        try MemberBlockItemListSyntax {
            for (enumName, category) in input.data {
                try generateSemanticEnum(for: enumName, category: category)
            }
        }
    }

    return try EnumDeclSyntax(
        leadingTrivia: .newline,
        modifiers: [.init(name: .keyword(.public, trailingTrivia: .space))],
        name: .identifier(input.identifier, leadingTrivia: .space, trailingTrivia: .space),
        memberBlockBuilder: memberBlockBuilder,
        trailingTrivia: .newline
    )
}

private func generateNumberTopLevelEnum(with input: NumberInput) -> EnumDeclSyntax {
    let memberBlockBuilder = {
        MemberBlockItemListSyntax {
            for (name, info) in input.data {
                generateNumberVariable(for: name, info: info)
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

private func generateSemanticEnum(for name: String, category: [String: ColorInfo]) throws -> EnumDeclSyntax {
    let memberBlock = try MemberBlockSyntax {
        for (name, info) in category {
            try generateSemanticVariable(for: name, with: info)
        }
    }

    return EnumDeclSyntax(
        leadingTrivia: .newlines(2),
        modifiers: [.init(name: .keyword(.public, trailingTrivia: .space))],
        name: .identifier(name.toPascalCase(), leadingTrivia: .space, trailingTrivia: .space),
        memberBlock: memberBlock
    )
}

private func generateNumberVariable(for name: String, info: NumberInfo) -> DeclSyntax {
    let variableName = name.sanitizeNumberVariableName()

    return DeclSyntax(
    """
    \n
    public static let \(raw: variableName) = CGFloat(\(raw: info.value))
    \n
    """
    )
}

private func generateSemanticVariable(for name: String, with info: ColorInfo) throws -> DeclSyntax {
    guard let rbga = info.rgba else {
        throw CodegenError.inputIsWrong(reason: "Codegen: unable to parse Color(\(name))")
    }

    let variableName = name.sanitizeSemanticVariableName()

    return DeclSyntax(
    """
    \n
    public static let \(raw: variableName) = UIColor(red: \(raw: rbga.red), green: \(raw: rbga.green), blue: \(raw: rbga.blue), alpha: \(raw: rbga.alpha))
    \n
    """
    )
}
