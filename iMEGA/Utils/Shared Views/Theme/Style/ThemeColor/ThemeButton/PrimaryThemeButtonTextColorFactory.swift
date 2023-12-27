import Foundation

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return MEGAAppColor.White._FFFFFF.uiColor
        }

        func disabledColor() -> UIColor {
            return MEGAAppColor.Gray._999999.uiColor
        }

        func highlightedColor() -> UIColor {
            return MEGAAppColor.White._FFFFFF30.uiColor
        }
    }

    // MARK: - Light Background Color

    struct LightPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

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
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return MEGAAppColor.White._FFFFFF.uiColor
        }

        func disabledColor() -> UIColor {
            return MEGAAppColor.Gray._999999.uiColor
        }

        func highlightedColor() -> UIColor {
            return MEGAAppColor.White._FFFFFF30.uiColor
        }
    }

    // MARK: - Dark Background Color

    struct DarkPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return MEGAAppColor.Green._00C29A.uiColor
        }

        func disabledColor() -> UIColor {
            return MEGAAppColor.Gray._999999.uiColor
        }

        func highlightedColor() -> UIColor {
            return MEGAAppColor.Green._00C29A.uiColor
        }
    }
}
