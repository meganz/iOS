import Foundation

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> ThemeColor {
            ThemeColor(red: 0, green: 168, blue: 134)
        }

        func disabledColor() -> ThemeColor {
            ThemeColor(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> ThemeColor {
            ThemeColor(red: 0, green: 168, blue: 134, alpha: 77)
        }
    }

    // MARK: - Light Background Color

    struct LightSecondaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> ThemeColor {
            ThemeColor(red: 255, green: 255, blue: 255)
        }

        func disabledColor() -> ThemeColor {
            ThemeColor(red: 255, green: 255, blue: 255)
        }

        func highlightedColor() -> ThemeColor {
            ThemeColor(red: 255, green: 255, blue: 255)
        }
    }
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> ThemeColor {
            ThemeColor(red: 0, green: 194, blue: 154)
        }

        func disabledColor() -> ThemeColor {
            ThemeColor(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> ThemeColor {
            ThemeColor(red: 0, green: 194, blue: 154, alpha: 77)
        }
    }

    // MARK: - Dark Background Color

    struct DarkSecondaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> ThemeColor {
            ThemeColor(red: 54, green: 54, blue: 56)
        }

        func disabledColor() -> ThemeColor {
            ThemeColor(red: 255, green: 255, blue: 255)
        }

        func highlightedColor() -> ThemeColor {
            ThemeColor(red: 54, green: 54, blue: 56)
        }
    }
}
