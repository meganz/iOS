import Foundation

///  Parses a given rbga (red, blue, green and alpha) string into a struct containing normalized rgba values
///
///  - Parameters:
///     - rgbaString: A string in the format: `rgba(255, 255, 255, 0.8000)`
///
///   - Returns: A struct representing normalized rbga values of type `RGBA` or `nil` if the string can't be parsed
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

///  Parses a given hexadecimal color string into a struct containing normalized rgba values
///
///  - Parameters:
///     - hexString: A string in the format: `#c4320a` or `c4320a`
///
/// - Returns: A struct representing normalized rbga values of type `RGBA` or `nil` if the string can't be parsed
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

/// Parses a given JSON dictionary to a nested structure containing color information.
///
/// - Parameters:
///    - colorsInformation: A dictionary with a string key and `Any` matching the expected JSON structure.
///    The JSON structure should resemble a nested key-value pair where the value can either be another dictionary (representing a category)
///    or a dictionary containing color information (`ColorInfo`)
///
/// - Returns: A `ColorData` dictionary that contains the hierarchical structure of color categories and their corresponding color information
func extractColorData(from colorsInformation: [String: Any]) -> ColorData {
    colorsInformation.reduce(into: [:]) { (result, entry) in
        let (key, value) = entry
        guard let valueDict = value as? [String: Any] else { return }
        result[key] = extractCategory(from: valueDict)
    }
}

let decoder = JSONDecoder()

private func extractCategory(from dict: [String: Any]) -> ColorCategory {
    var isLeaf = true
    var infoDict: ColorInfoDict = [:]
    var categoryDict: [String: ColorCategory] = [:]

    for (key, value) in dict {
        if let innerDict = value as? [String: Any],
           innerDict["$type"] as? String != nil,
           innerDict["$value"] as? String != nil {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                let colorInfo = try decoder.decode(ColorInfo.self, from: jsonData)
                infoDict[key] = colorInfo
            } catch {
                print("Error: couldn't decode ColorInfo for \(key) with Error(\(String(describing: error)))")
            }
        } else if let innerDict = value as? [String: Any] {
            isLeaf = false
            categoryDict[key] = extractCategory(from: innerDict)
        }
    }

    return isLeaf ? .leaf(infoDict) : .node(categoryDict)
}
