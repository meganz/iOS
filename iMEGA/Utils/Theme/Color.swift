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

extension Color {

    // MARK: - Text

    /// RGB(0, 0, 0, 0.8), Dark gray
    static var textLightPrimary: Color { Color.Text.lightPrimary }

    /// RGB(0, 0, 0, 0.8), Dark gray
    static var textLightPrimaryGreen: Color { Color.Text.lightPrimaryGreen }

    /// RGB(255, 255, 255, 1), White
    static var textDarkPrimary: Color { Color.Text.darkPrimary }

    /// RGB(0, 168, 0, 134, 1), Green
    static var textGreenPrimary: Color { Color.Text.greenPrimary }

    /// RGB(200, 241, 236, 1), Light Green
    static var textGreenSecondary: Color { Color.Text.greenSecondary }

    // MARK: - Background

    /// RGB(255, 255, 255, 1), White
    static var backgroundDefaultLight: Color { Color.Background.defaultLight }

    /// RGB(255, 204, 0, 0.15), Very light yellow
    static var backgroundWarningYellow: Color { Color.Background.warning }

    /// RGB(0, 168, 0, 134, 1), Green
    static var backgroundEnabledPrimary: Color { Color.Background.enabledPrimary }

    /// RGB(0, 168, 0, 134, 0.8), Green with 0.8 alpha
    static var backgroundHighlightedPrimary: Color { Color.Background.highlightedPrimary }

    /// RGB(153, 153, 153, 1), Gray
    static var backgroundDisabledPrimary: Color { Color.Background.disabledPrimary }

    // MARK: - Border

    /// RGB(255, 204, 0, 1), Yellow
    static var borderWarningYellow: Color { Color.Border.warning }

    // MARK: - Shadow
    static var shadowPrimary: Color { Color.Shadow.primary }
}

extension Color {

    enum Text {

        /// RGB(0, 0, 0, 0.8), Dark gray
        static let darkPrimary = Color(red: 0, green: 0, blue: 0, alpha: 204)

        /// RGB(255, 255, 255, 1), White
        static let lightPrimary = Color(red: 255, green: 255, blue: 255)

        /// RGB(255, 255, 255, 1), White
        static let lightPrimaryGreen = Color(red: 53, green: 211, blue: 196)

        /// RGB(0, 168, 0, 134, 1), Green
        static let greenPrimary = Color(red: 0, green: 168, blue: 134, alpha: 255)

        /// RGB(200, 241, 236, 1), Light Green
        static let greenSecondary = Color(red: 200, green: 241, blue: 236, alpha: 255)
    }

    enum Background {

        /// RGB(255, 255, 255, 1), White
        static let defaultLight = Color(red: 255, green: 255, blue: 255)

        /// RGB(255, 204, 0, 0.15), Very light yellow
        static let warning = Color(red: 255, green: 204, blue: 0, alpha: 38)

        // MARK: - Button

        /// RGB(0, 168, 0, 134, 1), Green
        static let enabledPrimary = Color(red: 0, green: 168, blue: 134, alpha: 255)

        /// RGB(0, 168, 0, 134, 0.8), Green with 0.8 alpha
        static let highlightedPrimary = Color(red: 0, green: 168, blue: 134, alpha: 204)

        /// RGB(153, 153, 153, 1), Gray
        static let disabledPrimary = Color(red: 153, green: 153, blue: 153, alpha: 255)
    }

    enum Border {

        /// RGB(255, 204, 0, 1), Yellow
        static let warning = Color(red: 255, green: 204, blue: 0)
    }

    enum Shadow {

        /// RGB(232, 232, 232, 1), Light Grey
        static let primary = Color(red: 232, green: 232, blue: 232)
    }
}
