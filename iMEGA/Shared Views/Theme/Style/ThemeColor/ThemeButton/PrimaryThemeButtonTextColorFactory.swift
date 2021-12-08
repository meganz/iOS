import Foundation

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> ThemeColor {
            ThemeColor(red: 255, green: 255, blue: 255, alpha: 255)
        }

        func disabledColor() -> ThemeColor {
            ThemeColor(red: 153, green: 153, blue: 153)
        }

        func highlightedColor() -> ThemeColor {
            ThemeColor(red: 255, green: 255, blue: 255, alpha: 77)
        }
    }

    // MARK: - Light Background Color

    struct LightPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> ThemeColor {
            ThemeColor(red: 0, green: 168, blue: 134, alpha: 255)
        }

        func disabledColor() -> ThemeColor {
            ThemeColor(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> ThemeColor {
            ThemeColor(red: 0, green: 168, blue: 134, alpha: 255)
        }
    }
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> ThemeColor {
            ThemeColor(red: 255, green: 255, blue: 255)
        }

        func disabledColor() -> ThemeColor {
            ThemeColor(red: 153, green: 153, blue: 153)
        }

        func highlightedColor() -> ThemeColor {
            ThemeColor(red: 255, green: 255, blue: 255, alpha: 77)
        }
    }

    // MARK: - Dark Background Color

    struct DarkPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> ThemeColor {
            ThemeColor(red: 0, green: 194, blue: 154, alpha: 255)
        }

        func disabledColor() -> ThemeColor {
            ThemeColor(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> ThemeColor {
            ThemeColor(red: 0, green: 194, blue: 154, alpha: 255)
        }
    }
}
