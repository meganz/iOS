import Foundation

protocol Token: Decodable {
    var properties: TokenProperties { get }
    init(properties: TokenProperties)
}

extension Token {
    init(from decoder: Decoder) throws {
        let properties = try TokenProperties(from: decoder)
        self.init(properties: properties)
    }
}

struct TokenProperties: Decodable {
    let type: String
    let value: String

    enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }
}

struct ColorInfo: Token {
    let properties: TokenProperties

    var rgba: RGBA? {
        properties.value.starts(with: "#") ? parseHex(properties.value) : parseRGBA(properties.value)
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
