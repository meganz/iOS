import Foundation

struct DarkColorThemeFactory: ColorFactory {

    func textColor(_ style: MEGAColor.Text) -> Color {
        switch style {
        case .primary: return Color(red: 255, green: 255, blue: 255)
        case .secondary: return Color(red: 155, green: 155, blue: 155)
        case .tertiary: return Color(red: 209, green: 209, blue: 209)
        case .quaternary: return Color(red: 181, green: 181, blue: 181)
        case .warning: return Color(red: 255, green: 69, blue: 58, alpha: 255)
        }
    }

    func backgroundColor(_ style: MEGAColor.Background) -> Color {
        switch style {
        case .primary: return Color(red: 28, green: 28, blue: 30)
        case .secondary: return Color(red: 84, green: 90, blue: 104)

        case .warning: return Color(red: 255, green: 214, blue: 0, alpha: 20)
        case .enabled: return Color(red: 0, green: 168, blue: 134, alpha: 255)
        case .disabled: return Color(red: 153, green: 153, blue: 153, alpha: 255)
        case .highlighted: return Color(red: 0, green: 168, blue: 134, alpha: 204)

        case .searchTextField: return Color(red: 41, green: 41, blue: 44)

        case .homeTopSide: return Color(red: 0, green: 0, blue: 0)
        }
    }


    func tintColor(_ style: MEGAColor.Tint) -> Color {
        switch style {
        case .primary: return Color(red: 209, green: 209, blue: 209)
        case .secondary: return Color(red: 64, green: 64, blue: 64)
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

    func shadowColor(_ style: MEGAColor.Shadow) -> Color {
        switch style {
        case .primary: return Color(red: 0, green: 0, blue: 0)
        }
    }
}
