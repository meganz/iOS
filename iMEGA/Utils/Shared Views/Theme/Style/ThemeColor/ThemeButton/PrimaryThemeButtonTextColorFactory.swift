import Foundation

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return .white
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
            return UIColor.green00A886
        }

        func disabledColor() -> UIColor {
            return MEGAAppColor.Gray._999999.uiColor
        }

        func highlightedColor() -> UIColor {
            return UIColor.green00A886
        }
    }
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return .white
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
            return UIColor.green00C29A
        }

        func disabledColor() -> UIColor {
            return MEGAAppColor.Gray._999999.uiColor
        }

        func highlightedColor() -> UIColor {
            return UIColor.green00C29A
        }
    }
}
