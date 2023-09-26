import Foundation

enum ParseInputError: Equatable, Error {
    case wrongArguments
}

struct ParseInputPayload {
    let core: URL
    let semanticDark: URL
    let semanticLight: URL
}

/// Parses a pseudo-array formatted string to extract and validate file paths for core, semantic dark, and semantic light tokens.
///
/// The function expects the input string to be formatted as a pseudo-array containing paths like so:
/// "[Path/To/Semantic tokens.Light.tokens.json, Path/To/Semantic tokens.Dark.tokens.json, Path/To/core.json]"
/// 
/// - Parameter input: The input string formatted as a pseudo-array.
/// - Returns: A `ParseInputPayload` object containing the parsed and validated paths.
/// - Throws: A `ParseInputError` if the number of arguments is incorrect or if any of the paths does not contain the expected file name.
func parseInput(_ input: String) throws -> ParseInputPayload {
    let parsed = input
        .replacingOccurrences(of: "[\\[\\]]", with: "", options: .regularExpression, range: nil)
        .split(separator: ",")
        .map {
            String($0)
                .deletingPrefix(" ")
        }

    guard parsed.count == 3 else {
        throw ParseInputError.wrongArguments
    }

    let inputMap: [ExpectedInput: String] = parsed.reduce(into: [:]) { acc, input in
        switch input {
        case input where input.contains(ExpectedInput.core.rawValue):
            acc[.core] = input
        case input where input.contains(ExpectedInput.semanticDark.rawValue):
            acc[.semanticDark] = input
        case input where input.contains(ExpectedInput.semanticLight.rawValue):
            acc[.semanticLight] = input
        default:
            break
        }
    }

    guard
        let corePath = inputMap[.core],
        let semanticDarkPath = inputMap[.semanticDark],
        let semanticLightPath = inputMap[.semanticLight]
    else {
        throw ParseInputError.wrongArguments
    }

    let mapped = [corePath, semanticDarkPath, semanticLightPath].map { URL(fileURLWithPath: $0) }

    return .init(core: mapped[0], semanticDark: mapped[1], semanticLight: mapped[2])
}

///  Parses a given rbga (red, blue, green and alpha) string into a struct containing normalized rgba values.
///
///  - Parameters:
///     - rgbaString: A string in the format: `rgba(255, 255, 255, 0.8000)`.
///
///  - Returns: A struct representing normalized rbga values of type `RGBA` or `nil` if the string can't be parsed.
func parseRGBA(_ rgbaString: String) -> RGBA? {
    guard let range = rgbaString.range(of: "^rgba\\((.*)\\)$", options: .regularExpression) else {
          return nil
      }

    let sanitizedRgbaString = rgbaString[range]
        .replacingOccurrences(of: "rgba(", with: "")
        .replacingOccurrences(of: ")", with: "")

    let rgbaComponents = sanitizedRgbaString
        .split(separator: ",")
        .compactMap {
            String($0)
                .trimmingCharacters(in: .whitespaces)
                .toCGFloat()
        }

    guard rgbaComponents.count == 4 else {
        return nil
    }

    let (red, blue, green, alpha) = (rgbaComponents[0], rgbaComponents[1], rgbaComponents[2], rgbaComponents[3])

    // Normalization
    return .init(red: red / 255.0,  green: green / 255.0, blue: blue / 255.0, alpha: alpha)
}

///  Parses a given hexadecimal color string into a struct containing normalized rgba values.
///
///  - Parameters:
///     - hexString: A string in the format: `#c4320a` or `c4320a`.
///
///  - Returns: A struct representing normalized rbga values of type `RGBA` or `nil` if the string can't be parsed.
func parseHex(_ hexString: String) -> RGBA? {
    var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    // Ensure that input is valid
    let hexSet = CharacterSet(charactersIn: "0123456789abcdef")
    guard hexSanitized.rangeOfCharacter(from: hexSet.inverted) == nil else {
        return nil
    }

    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    guard hexSanitized.count == 6 else {
        return nil
    }

    let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
    let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
    let blue = CGFloat(rgb & 0x0000FF) / 255.0

    return RGBA(red: red, green: green, blue: blue, alpha: 1.0)
}

private let decoder = JSONDecoder()

/// Parses a given JSON dictionary to a flat structure containing color information.
///
/// - Parameters:
///   - colorsInformation: A dictionary with a string key and `Any` matching the expected JSON structure.
///     The JSON should resemble a nested key-value pair where the value can be either another dictionary (representing a category)
///     or a dictionary containing color information (`ColorInfo`).
///   - path: The current nested path as a string, used for recursion. Defaults to an empty string.
///
/// - Returns: A dictionary of type `[String: ColorInfo]` containing the flattened color information.
func extractFlatColorData(from colorsInformation: [String: Any], path: String = "") -> [String: ColorInfo] {
    var flatMap: [String: ColorInfo] = [:]

    for (key, value) in colorsInformation {
        let fullPath = path.isEmpty ? key : "\(path).\(key)"
        if let innerDict = value as? [String: Any],
           innerDict["$type"] as? String != nil,
           innerDict["$value"] as? String != nil {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                let colorInfo = try decoder.decode(ColorInfo.self, from: jsonData)
                flatMap[fullPath] = colorInfo
            } catch {
                print("Error: couldn't decode ColorInfo for \(key) with Error(\(String(describing: error)))")
            }
        } else if let innerDict = value as? [String: Any] {
            let nestedMap = extractFlatColorData(from: innerDict, path: fullPath)
            flatMap.merge(nestedMap) { (_, new) in new }
        }
    }

    return flatMap
}

/// Parses a given JSON dictionary to a nested structure containing color information.
///
/// - Parameters:
///   - colorsInformation: A dictionary with a string key and `Any` matching the expected JSON structure.
///   - flatMap: The flat `[String: ColorInfo]` map used for O(1) lookups.
///
/// - Returns: A `ColorData` dictionary that contains the hierarchical structure of color categories and their corresponding color information.
func extractColorData(from colorsInformation: [String: Any], using flatMap: [String: ColorInfo]) -> ColorData {
    colorsInformation.reduce(into: [:]) { (result, entry) in
        let (key, value) = entry
        guard let valueDict = value as? [String: Any] else { return }
        result[key] = extractCategory(from: valueDict, using: flatMap)
    }
}

private func extractCategory(from dict: [String: Any], using flatMap: [String: ColorInfo]) -> ColorCategory {
    var isLeaf = true
    var infoDict: ColorInfoDict = [:]
    var categoryDict: [String: ColorCategory] = [:]

    for (key, value) in dict {
        if let innerDict = value as? [String: Any],
           let valueType = innerDict["$type"] as? String,
           let valueRef = innerDict["$value"] as? String {
            let sanitizedValueRef = sanitizeValueRef(valueRef)

            // O(1) lookup
            if let colorInfo = flatMap[sanitizedValueRef], valueType == "color" {
                infoDict[key] = colorInfo
            } else {
                print("Error: couldn't lookup ColorInfo for \(key)")
            }
        } else if let innerDict = value as? [String: Any] {
            isLeaf = false
            categoryDict[key] = extractCategory(from: innerDict, using: flatMap)
        }
    }

    return isLeaf ? .leaf(infoDict) : .node(categoryDict)
}

private func sanitizeValueRef(_ valueRef: String) -> String {
    valueRef
        .replacingOccurrences(of: "[\\{\\}]", with: "", options: .regularExpression, range: nil)
        .deletingPrefix("Colors.")
}
