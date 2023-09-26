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

    let coreColorMap = try generateCoreColorMap(with: coreURL)

    let semanticDarkInput = try generateSemanticInput(with: semanticDarkURL, using: coreColorMap, isDark: true)

    let semanticLightInput = try generateSemanticInput(with: semanticLightURL, using: coreColorMap, isDark: false)

    let generatedCode = try generateCode(from: .init(dark: semanticDarkInput, light: semanticLightInput))

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

private func generateCoreColorMap(with url: URL) throws -> [String: ColorInfo] {
    let coreJSONObject = try extractJSON(from: url)

    guard let coreColorsInformation = coreJSONObject["Colors"] as? [String: Any] else {
        print("Error: couldn't find 'Colors' key in \(ExpectedInput.core.rawValue) input")
        abort(.badInputJSON)
    }

    return extractFlatColorData(from: coreColorsInformation)
}

private func generateSemanticInput(with url: URL, using map: [String: ColorInfo], isDark: Bool) throws -> SemanticInput {
    let jsonObject = try extractJSON(from: url)
    let data = extractColorData(from: jsonObject, using: map)

    return isDark ? .dark(data) : .light(data)
}
