import Foundation

struct Color: Codable {
    typealias ColorValue = UInt8

    let red: ColorValue
    let green: ColorValue
    let blue: ColorValue
    var alpha: ColorValue = 255
}

extension Color {

    func altering(alpha: ColorValue) -> Self {
        return Self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Color: ColorProviding {
    var uiColor: UIColor {
        UIColor.rgbColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Color {

    var asTextColorStyle: ColorStyle {
        ColorStyle(color: self, type: .foreground)
    }

    var asBackgroundColorStyle: ColorStyle {
        ColorStyle(color: self, type: .background)
    }
}

extension Color {

    enum Text {

        /// RGB(0, 0, 0, 0.8), Dark gray
        static let darkPrimary = Color(red: 0, green: 0, blue: 0, alpha: 204)

        // MARK: - White

        /// RGB(255, 255, 255, 1), White
        static let lightPrimary = Color(red: 255, green: 255, blue: 255)

        // MARK: - Grey

        /// Grey RGB(155, 155, 155, 1), `9B9B9B`
        static let greyPrimary = Color(red: 155, green: 155, blue: 155)

        // MARK: - Green

        /// RGB(255, 255, 255, 1), White
        static let lightPrimaryGreen = Color(red: 53, green: 211, blue: 196)

        /// RGB(0, 168, 134, 1), Green
        static let greenPrimary = Color(red: 0, green: 168, blue: 134, alpha: 255)

        /// RGB(200, 241, 236, 1), Light Green
        static let greenSecondary = Color(red: 200, green: 241, blue: 236, alpha: 255)

        // MARK: - Red

        /// RGB(217, 0, 7, 1), Red
        static let redPrimary = Color(red: 217, green: 0, blue: 7, alpha: 255)
    }

    enum Background {

        /// RGB(255, 255, 255, 1), White
        static let defaultLight = Color(red: 255, green: 255, blue: 255)

        /// RGB(255, 204, 0, 0.15), Very light yellow
        static let warning = Color(red: 255, green: 204, blue: 0, alpha: 38)

        // MARK: - Button

        /// RGB(0, 168, 134, 1), Green
        static let enabledPrimary = Color(red: 0, green: 168, blue: 134, alpha: 255)

        /// RGB(0, 168, 134, 0.8), Green with 0.8 alpha
        static let highlightedPrimary = Color(red: 0, green: 168, blue: 134, alpha: 204)

        /// RGB(153, 153, 153, 1), Gray
        static let disabledPrimary = Color(red: 153, green: 153, blue: 153, alpha: 255)
    }

    enum Border {

        /// RGB(255, 204, 0, 1), Yellow
        static let warning = Color(red: 255, green: 204, blue: 0)

        /// RGB(200, 200, 200, 1), Grey
        static var grey: Color { Color(red: 200, green: 200, blue: 200) }
    }

    enum Shadow {

        /// RGB(232, 232, 232, 1), Light Grey
        static let primary = Color(red: 232, green: 232, blue: 232)
    }
}
