import Foundation

struct LightColorThemeFactory: ColorFactory {

    func textColor(_ style: MEGAColor.Text) -> ThemeColor {
        switch style {
        case .primary: return ThemeColor(red: 0, green: 0, blue: 0)
        case .secondary: return ThemeColor(red: 153, green: 153, blue: 153)
        case .tertiary: return ThemeColor(red: 81, green: 81, blue: 81)
        case .quaternary: return ThemeColor(red: 132, green: 132, blue: 132)
        case .warning: return ThemeColor(red: 255, green: 59, blue: 48)
        }
    }

    func backgroundColor(_ style: MEGAColor.Background) -> ThemeColor {
        switch style {
        case .primary: return ThemeColor(red: 255, green: 255, blue: 255)
        case .secondary: return ThemeColor(red: 196, green: 204, blue: 204, alpha: 255)

        case .warning: return ThemeColor(red: 255, green: 204, blue: 0, alpha: 8)
        case .enabled: return ThemeColor(red: 0, green: 168, blue: 134, alpha: 255)
        case .disabled: return ThemeColor(red: 153, green: 153, blue: 153, alpha: 255)
        case .highlighted: return ThemeColor(red: 0, green: 168, blue: 134, alpha: 204)

        case .searchTextField: return ThemeColor(red: 232, green: 232, blue: 232)
        case .homeTopSide: return ThemeColor(red: 247, green: 247, blue: 247)
        }
    }

    func tintColor(_ style: MEGAColor.Tint) -> ThemeColor {
        switch style {
        case .primary: return ThemeColor(red: 81, green: 81, blue: 81)
        case .secondary: return ThemeColor(red: 196, green: 196, blue: 196)
        }
    }

    func borderColor(_ style: MEGAColor.Border) -> ThemeColor {
        switch style {
        case .primary: return ThemeColor(red: 0, green: 0, blue: 0, alpha: 38)
        case .warning: return ThemeColor(red: 255, green: 204, blue: 0)
        }
    }

    func themeButtonTextFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory {
        switch style {
        case .primary:
            return LightPrimaryThemeButtonTextColorFactory()
        case .secondary:
            return LightSecondaryThemeButtonTextColorFactory()
        }
    }

    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory {
        switch style {
        case .primary:
            return LightPrimaryThemeButtonBackgroundColorFactory()
        case .secondary:
            return LightSecondaryThemeButtonBackgroundColorFactory()
        }
    }

    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> ThemeColor {
        switch style {
        case .warning: return backgroundColor(.warning)
        }
    }

    func shadowColor(_ style: MEGAColor.Shadow) -> ThemeColor {
        switch style {
        case .primary: return ThemeColor(red: 0, green: 0, blue: 0)
        }
    }
}
