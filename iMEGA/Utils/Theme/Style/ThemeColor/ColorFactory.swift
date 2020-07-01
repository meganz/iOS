import Foundation

func createColorFactory(from theme: InterfaceStyle) -> ColorFactory {
    switch theme {
    case .light: return LightColorThemeFactory()
    case .dark: return DarkColorThemeFactory()
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
}
