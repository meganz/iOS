import Foundation

struct DarkColorThemeFactory: ColorFactory {

    func textColor(_ style: MEGAColor.Text) -> Color {
        switch style {
        case .primary: return Color(red: 255, green: 255, blue: 255)
        case .invertedPrimary: return Color(red: 0, green: 0, blue: 0)
        case .secondary: return Color(red: 155, green: 155, blue: 155)
        case .warning: return Color(red: 217, green: 0, blue: 7, alpha: 255)
        }
    }

    func backgroundColor(_ style: MEGAColor.Background) -> Color {
        switch style {
        case .primary: return Color(red: 28, green: 28, blue: 30)
        case .warning: return Color(red: 255, green: 214, blue: 0, alpha: 20)
        case .enabled: return Color(red: 0, green: 168, blue: 134, alpha: 255)
        case .disabled: return Color(red: 153, green: 153, blue: 153, alpha: 255)
        case .highlighted: return Color(red: 0, green: 168, blue: 134, alpha: 204)
        }
    }

    func borderColor(_ style: MEGAColor.Border) -> Color {
        switch style {
        case .primary: return Color(red: 0, green: 0, blue: 0, alpha: 38)
        case .warning: return Color(red: 255, green: 214, blue: 0)
        }
    }

    func themeButtonTextFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory {
        switch style {
        case .primary:
            return DarkPrimaryThemeButtonTextColorFactory()
        case .secondary:
            return DarkSecondaryThemeButtonTextColorFactory()
        }
    }

    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory {
        switch style {
        case .primary:
            return DarkPrimaryThemeButtonBackgroundColorFactory()
        case .secondary:
            return DarkSecondaryThemeButtonBackgroundColorFactory()
        }
    }

    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> Color {
        switch style {
        case .warning: return backgroundColor(.warning)
        }
    }
}
