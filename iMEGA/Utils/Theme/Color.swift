import Foundation

struct Color: Codable {
    typealias ColorValue = UInt8

    let red: ColorValue
    let green: ColorValue
    let blue: ColorValue
    var alpha: ColorValue = 255
}

func uiColor(from colorProvider: ColorProviding) -> UIColor {
    return colorProvider.uiColor
}

extension Color {
    static var white: Color { return Color(red: 255, green: 255, blue: 255) }
}

extension Color: ColorProviding {
    var uiColor: UIColor {
        UIColor.rgbColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Color {

    enum Text {

        /// RGB(0, 0, 0, 0.8)
        static let darkPrimary = Color(red: 0, green: 0, blue: 0, alpha: 204)

        /// RGB(255, 255, 255, 1)
        static let lightPrimary = Color(red: 255, green: 255, blue: 255)
    }

    enum Background {
        static let `default` = Color(red: 0, green: 0, blue: 0)
        static let warning = Color(red: 255, green: 204, blue: 0, alpha: 38)
    }

    enum Border {
        static let warning = Color(red: 255, green: 204, blue: 0)
    }
}
