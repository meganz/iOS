import Foundation

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 255, green: 255, blue: 255, alpha: 255)
        }

        func disabledColor() -> Color {
            Color(red: 153, green: 153, blue: 153)
        }

        func highlightedColor() -> Color {
            Color(red: 53, green: 211, blue: 196)
        }
    }

    // MARK: - Light Background Color

    struct LightPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 0, green: 168, blue: 134, alpha: 255)
        }

        func disabledColor() -> Color {
            Color(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> Color {
            Color(red: 0, green: 168, blue: 134, alpha: 255)
        }
    }
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 255, green: 255, blue: 255)
        }

        func disabledColor() -> Color {
            Color(red: 153, green: 153, blue: 153)
        }

        func highlightedColor() -> Color {
            Color(red: 53, green: 211, blue: 196)
        }
    }

    // MARK: - Dark Background Color

    struct DarkPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 0, green: 194, blue: 154, alpha: 255)
        }

        func disabledColor() -> Color {
            Color(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> Color {
            Color(red: 0, green: 168, blue: 134, alpha: 255)
        }
    }
}
