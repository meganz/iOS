import Foundation

let arguments = ProcessInfo().arguments

guard arguments.count == 3 else {
    print("Error: wrong arguments")
    abort(.wrongArguments)
}

let (input, output) = (arguments[1], arguments[2])

guard output.hasSuffix(".swift") else {
    print("Error: output file must be a .swift file")
    abort(.outputFileIsNotSwift)
}

do {
    let parsedInput = try parseInput(input)

    let (coreURL, semanticDarkURL, semanticLightURL) = (parsedInput.core, parsedInput.semanticDark, parsedInput.semanticLight)

    let coreJSONObject = try extractJSON(from: coreURL)

    let coreColorMap = try generateCoreColorMap(with: coreJSONObject)

    let spacingInput = try generateSpacingInput(with: coreJSONObject)

    let radiusInput = try generateRadiusInput(with: coreJSONObject)

    let semanticDarkInput = try generateSemanticInput(with: semanticDarkURL, using: coreColorMap, isDark: true)

    let semanticLightInput = try generateSemanticInput(with: semanticLightURL, using: coreColorMap, isDark: false)

    let codegenInput: CodegenInput = .init(dark: semanticDarkInput, light: semanticLightInput, spacing: spacingInput, radius: radiusInput)

    let generatedCode = try generateCode(with: codegenInput)

    let outputURL = URL(fileURLWithPath: output)

    try generatedCode.write(to: outputURL, atomically: true, encoding: .utf8)

} catch {
    print("Error: failed to execute TokenCodegenGenerator with Error(\(String(describing: error)))")
    abort(.other)
}

enum AbortReason: Int32 {
    case wrongArguments = 1
    case outputFileIsNotSwift = 2
    case badInputJSON = 3
    case other = 4
}

enum ExpectedInput: String {
    case core = "core.json"
    case semanticDark = "Semantic tokens.Dark.tokens.json"
    case semanticLight = "Semantic tokens.Light.tokens.json"

    static var description: String {
        "[\(semanticLight.rawValue), \(semanticDark.rawValue), \(core.rawValue)]"
    }
}

private func abort(_ reason: AbortReason) -> Never {
    print("Usage: TokenCodegenGenerator \(ExpectedInput.description) output.swift")
    exit(reason.rawValue)
}

private func extractJSON(from url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)

    guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
        print("Error: couldn't serialize .json core input into jsonObject")
        abort(.badInputJSON)
    }

    return jsonObject
}

enum CoreTokensKey: String {
    case colors = "Colors"
    case spacing = "Spacing"
    case radius = "Radius"
}

private func extractCoreTokensJSONObject(from coreJSONObject: [String: Any], with key: CoreTokensKey) throws -> [String: Any] {
    guard let coreTokenJSONObject = coreJSONObject[key.rawValue] as? [String: Any] else {
        print("Error: couldn't find '\(key.rawValue)' key in \(ExpectedInput.core.rawValue) input")
        abort(.badInputJSON)
    }

    return coreTokenJSONObject
}

private func generateCoreColorMap(with coreJSONObject: [String: Any]) throws -> [String: ColorInfo] {
    let coreColorsJSONObject = try extractCoreTokensJSONObject(from: coreJSONObject, with: .colors)
    let data = try extractFlatColorData(from: coreColorsJSONObject)

    return data
}

private func generateSemanticInput(with url: URL, using map: [String: ColorInfo], isDark: Bool) throws -> SemanticInput {
    let jsonObject = try extractJSON(from: url)
    let data = try extractColorData(from: jsonObject, using: map)

    return isDark ? .dark(data) : .light(data)
}

private func generateSpacingInput(with coreJSONObject: [String: Any]) throws -> NumberInput {
    let spacingJSONObject = try extractCoreTokensJSONObject(from: coreJSONObject, with: .spacing)
    let data = try extractNumberInfo(from: spacingJSONObject)

    return .spacing(data)
}

private func generateRadiusInput(with coreJSONObject: [String: Any]) throws -> NumberInput {
    let radiusJSONObject = try extractCoreTokensJSONObject(from: coreJSONObject, with: .radius)
    let data = try extractNumberInfo(from: radiusJSONObject)

    return .radius(data)
}
