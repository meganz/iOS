import Foundation

extension InterfaceStyle {

    var colorFactory: ColorFactory {
        switch self {
        case .light: return LightColorThemeFactory()
        case .dark: return DarkColorThemeFactory()
        }
    }
}

protocol ColorFactory {

    func textColor(_ style: MEGAColor.Text) -> Color

    func backgroundColor(_ style: MEGAColor.Background) -> Color

    func borderColor(_ style: MEGAColor.Border) -> Color

    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> Color

    // MARK: - Theme Button Factory

    func themeButtonTextFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory

    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory

    // MARK: - Independent

    func independent(_ style: MEGAColor.Independent) -> Color
}

extension ColorFactory {

    func independent(_ style: MEGAColor.Independent) -> Color {
        switch style {
        case .bright: return Color(red: 255, green: 255, blue: 255)
        }
    }
}
