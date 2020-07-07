import Foundation

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 0, green: 168, blue: 134)
        }

        func disabledColor() -> Color {
            Color(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> Color {
            Color(red: 155, green: 155, blue: 155)
        }
    }

    // MARK: - Light Background Color

    struct LightSecondaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 255, green: 255, blue: 255)
        }

        func disabledColor() -> Color {
            Color(red: 255, green: 255, blue: 255)
        }

        func highlightedColor() -> Color {
            Color(red: 255, green: 255, blue: 255)
        }
    }
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 0, green: 194, blue: 154)
        }

        func disabledColor() -> Color {
            Color(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> Color {
            Color(red: 155, green: 155, blue: 155)
        }
    }

    // MARK: - Dark Background Color

    struct DarkSecondaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 54, green: 54, blue: 56)
        }

        func disabledColor() -> Color {
            Color(red: 255, green: 255, blue: 255)
        }

        func highlightedColor() -> Color {
            Color(red: 255, green: 255, blue: 255)
        }
    }
}
