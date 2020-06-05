import Foundation

struct Color: Codable {
    typealias ColorValue = UInt8

    let red: ColorValue
    let green: ColorValue
    let blue: ColorValue
    var alpha: ColorValue = 255
}

extension Color: ColorProviding {
    var uiColor: UIColor {
        UIColor.rgbColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

func uiColor(from colorProvider: ColorProviding) -> UIColor {
    return colorProvider.uiColor
}

extension Color {

    // MARK: - Text

    /// RGB(0, 0, 0, 0.8), Dark gray
    static var textLightPrimary: Color { Color.Text.lightPrimary }

    /// RGB(255, 255, 255, 1), White
    static var textDarkPrimary: Color { Color.Text.darkPrimary }

    // MARK: - Background

    /// RGB(0, 0, 0, 1), White
    static var backgroundDefaultLight: Color { Color.Background.defaultLight }

    /// RGB(255, 204, 0, 0.15), Very light yellow
    static var backgroundWarningYellow: Color { Color.Background.warning }

    // MARK: - Border

    /// RGB(255, 204, 0, 1), Yellow
    static var borderWarningYellow: Color { Color.Border.warning }
}

extension Color {

    enum Text {

        /// RGB(0, 0, 0, 0.8), Dark gray
        static let darkPrimary = Color(red: 0, green: 0, blue: 0, alpha: 204)

        /// RGB(255, 255, 255, 1), White
        static let lightPrimary = Color(red: 255, green: 255, blue: 255)
    }

    enum Background {

        /// RGB(0, 0, 0, 1), White
        static let defaultLight = Color(red: 0, green: 0, blue: 0)

        /// RGB(255, 204, 0, 0.15), Very light yellow
        static let warning = Color(red: 255, green: 204, blue: 0, alpha: 38)
    }

    enum Border {

        /// RGB(255, 204, 0, 1), Yellow
        static let warning = Color(red: 255, green: 204, blue: 0)
    }
}
