import Foundation

struct ColorInfo: Codable {
    let type: String
    let value: String

    var rgba: RGBA? {
        if value.starts(with: "#") {
            return parseHex(value)
        } else {
            return parseRGBA(value)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }
}

typealias ColorInfoDict = [String: ColorInfo]

enum ColorCategory {
    case leaf(ColorInfoDict)
    case node([String: ColorCategory])
}

typealias ColorData = [String: ColorCategory]

struct RGBA {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
}
