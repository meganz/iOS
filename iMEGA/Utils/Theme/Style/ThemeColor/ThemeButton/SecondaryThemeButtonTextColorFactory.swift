import Foundation

extension LightColorThemeFactory {

    struct LightSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 0, green: 168, blue: 134, alpha: 255)
        }

        func disabledColor() -> Color {
            Color(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> Color {
            Color(red: 155, green: 155, blue: 155)
        }
    }

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

    struct DarkSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> Color {
            Color(red: 0, green: 168, blue: 134, alpha: 255)
        }

        func disabledColor() -> Color {
            Color(red: 153, green: 153, blue: 153, alpha: 255)
        }

        func highlightedColor() -> Color {
            Color(red: 155, green: 155, blue: 155)
        }
    }

    struct DarkSecondaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

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
