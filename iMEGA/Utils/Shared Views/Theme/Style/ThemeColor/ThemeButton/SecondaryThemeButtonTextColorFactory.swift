import Foundation

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return MEGAAppColor.Green._00A886.uiColor
        }

        func disabledColor() -> UIColor {
            return MEGAAppColor.Gray._999999.uiColor
        }

        func highlightedColor() -> UIColor {
            return MEGAAppColor.Green._00A886.uiColor
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
            return MEGAAppColor.Green._00C29A.uiColor
        }

        func disabledColor() -> UIColor {
            return MEGAAppColor.Gray._999999.uiColor
        }

        func highlightedColor() -> UIColor {
            return MEGAAppColor.Green._00C29A4D.uiColor
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
