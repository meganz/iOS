import Foundation

let arguments = ProcessInfo().arguments

guard arguments.count == 3 else {
    print("Error: wrong arguments")
    abort(.wrongArguments)
}

let (input, output) = (arguments[1], arguments[2])

guard input.hasSuffix(".json") else {
    print("Error: input file must be a .json file")
    abort(.inputFileIsNotJSON)
}

guard output.hasSuffix(".swift") else {
    print("Error: output file must be a .swift file")
    abort(.outputFileIsNotSwift)
}

let inputURL = URL(fileURLWithPath: input)

do {
    let jsonData = try Data(contentsOf: inputURL)

    guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
        print("Error: couldn't serialize .json input into jsonObject")
        abort(.badInputJSON)
    }

    guard let colorsInformation = jsonObject["Colors"] as? [String: Any] else {
        print("Error: couldn't find 'Colors' key in .json input")
        abort(.badInputJSON)
    }

    let colorData = extractColorData(from: colorsInformation)

    let generatedCode = try generateCode(from: colorData)

    let outputURL = URL(fileURLWithPath: output)

    try generatedCode.write(to: outputURL, atomically: true, encoding: .utf8)

} catch {
    print("Error: failed to execute TokenCodegenGenerator with Error(\(String(describing: error)))")
    abort(.other)
}

enum AbortReason: Int32 {
    case wrongArguments = 1
    case inputFileIsNotJSON = 2
    case outputFileIsNotSwift = 3
    case badInputJSON = 4
    case other = 5
}

func abort(_ reason: AbortReason) -> Never {
    print("Usage: TokenCodegenGenerator <input.json> <output.swift>")
    exit(reason.rawValue)
}
