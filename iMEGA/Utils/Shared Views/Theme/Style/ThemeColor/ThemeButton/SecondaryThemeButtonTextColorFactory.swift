import Foundation

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return UIColor.green00A886
        }

        func disabledColor() -> UIColor {
            return UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            return UIColor.green00A886
        }
    }

    // MARK: - Light Background Color

    struct LightSecondaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return .white
        }

        func disabledColor() -> UIColor {
            return .white
        }

        func highlightedColor() -> UIColor {
            return .white
        }
    }
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return UIColor.green00C29A
        }

        func disabledColor() -> UIColor {
            return UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            return UIColor.green00C29A4D
        }
    }

    // MARK: - Dark Background Color

    struct DarkSecondaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return MEGAAppColor.Black._363638.uiColor
        }

        func disabledColor() -> UIColor {
            return .white
        }

        func highlightedColor() -> UIColor {
            return MEGAAppColor.Black._363638.uiColor
        }
    }
}
