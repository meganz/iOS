import Foundation

struct ColorInfo: Decodable {
    let type: String
    var value: String

    enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }

    var rgba: RGBA? {
        value.starts(with: "#") ? parseHex(value) : parseRGBA(value)
    }
}

struct RGBA {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
}

typealias ColorData = [String: [String: ColorInfo]]

struct NumberInfo: Decodable {
    let type: String
    let value: Double

    enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }
}

typealias NumberData = [String: NumberInfo]
