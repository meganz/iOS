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
                .trimmingCharacters(in: .whitespaces)
        }

    guard parsed.count == 3 else {
        throw ParseInputError.wrongArguments
    }

    let inputMap: [ExpectedInput: String] = parsed.reduce(into: [:]) { result, input in
        switch input {
        case input where input.contains(ExpectedInput.core.rawValue):
            result[.core] = input
        case input where input.contains(ExpectedInput.semanticDark.rawValue):
            result[.semanticDark] = input
        case input where input.contains(ExpectedInput.semanticLight.rawValue):
            result[.semanticLight] = input
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
    return .init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
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
///   - colorsInformation: A dictionary with a string key and `Any` matching the expected `JSON` structure.
///     The JSON should resemble a nested key-value pair where the value can be either another dictionary,
///     or a dictionary containing color information (`ColorInfo`).
///
///     Example for the expected `JSON` structure - **NOTE**: It can be indefinitely nested.
/// ```
/// {
///     "Black opacity": {
///         "090": {
///             "$type": "color",
///             "$value": "rgba(0, 0, 0, 0.9000)"
///         }
///      },
///     "Secondary": {
///         "Orange": {
///             "100": {
///                 "$type": "color",
///                 "$value": "#ffead5"
///             }
///         }
///     }
/// }
/// ```
///   - path: The current nested path as a string, used for recursion. Defaults to an empty string.
///
/// - Returns: A dictionary of type `[String: ColorInfo]` containing the flattened color information.
/// 
/// - Complexity: Let n be the total number of keys in the input JSON object, including all nested keys - O(n)
func extractFlatColorData(from jsonObject: [String: Any], path: String = "") throws -> [String: ColorInfo] {
    var flatMap: [String: ColorInfo] = [:]

    for (key, value) in jsonObject {
        let fullPath = (path.isEmpty ? key : "\(path).\(key)").lowercased()

        if let innerDict = value as? [String: Any],
           innerDict["$type"] as? String != nil,
           innerDict["$value"] as? String != nil {

            let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
            let colorInfo = try decoder.decode(ColorInfo.self, from: jsonData)
            flatMap[fullPath] = colorInfo

        } else if let innerDict = value as? [String: Any] {
            let nestedMap = try extractFlatColorData(from: innerDict, path: fullPath)
            flatMap.merge(nestedMap) { _, new in new }
        }
    }

    return flatMap
}

enum ExtractColorDataError: Error {
    case inputIsWrong(reason: String)
}

/// Parses a given JSON dictionary to a nested structure containing semantic color information.
///
/// - Parameters:
///   - jsonData: A `Data` object matching the expected JSON structure.
///
///     Example for the expected `JSON` structure - **NOTE**: It can be only be nested one level.
/// ```
/// {
///     "Focus": {
///         "--color-focus": {
///             "$type": "color",
///             "$value": "{Colors.Secondary.Indigo.700}"
///         }
///     },
///     "Indicator": {
///         "--color-indicator-magenta": {
///             "$type": "color",
///             "$value": "{Colors.Secondary.Magenta.300}"
///         },
///         "--color-indicator-yellow": {
///             "$type": "color",
///             "$value": "{Colors.Warning.400}"
///         }
///     }
/// }
/// ```
///   - flatMap: The flat `[String: ColorInfo]` map used for O(1) lookups, containing core color information.
///
/// - Returns: A `ColorData` dictionary that contains the hierarchical structure of color categories and their corresponding color information.
///
/// - Complexity: Let m be the number of categories and n be the average number of semantic keys per category - O(mn)
func extractColorData(from jsonData: Data, using flatMap: [String: ColorInfo]) throws -> ColorData {
    var colorData = try decoder.decode(ColorData.self, from: jsonData)

    for (categoryKey, var categoryValue) in colorData {
        for (semanticKey, var semanticInfo) in categoryValue {
            let sanitizedValue = semanticInfo.value.sanitizeSemanticJSONKey()
            // O(1) lookup
            guard let coreColorInfo = flatMap[sanitizedValue] else {
                let reason = "Error: couldn't lookup ColorInfo for \(semanticKey) with value \(semanticInfo.value)"
                throw ExtractColorDataError.inputIsWrong(reason: reason)
            }
            semanticInfo.value = coreColorInfo.value
            categoryValue[semanticKey] = semanticInfo
        }
        colorData[categoryKey] = categoryValue
    }

    return colorData
}

/// Parses a given JSON dictionary to a `NumberData` structure containing number information.
///
/// - Parameters:
///   - jsonObject: A dictionary with a string key and `Any` matching the expected JSON structure.
///     The JSON should contain number information that `NumberData` can decode.
///
///     Example for the expected `JSON` structure:
/// ```
/// {
///     "--border-radius-circle": {
///         "$type": "number",
///         "$value": "0.5"
///     },
///     "--border-radius-extra-small": {
///         "$type": "number",
///         "$value": "2"
///      }
/// }
///  ```
/// - Throws:
///   - JSONSerialization errors: If the JSON object is not serializable.
///   - Decoding errors: If the JSON data can't be decoded into a `NumberData` object.
///
/// - Returns: A `NumberData` object containing the parsed number information.
func extractNumberInfo(from jsonObject: [String: Any]) throws -> NumberData {
    let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
    return try decoder.decode(NumberData.self, from: jsonData)
}
