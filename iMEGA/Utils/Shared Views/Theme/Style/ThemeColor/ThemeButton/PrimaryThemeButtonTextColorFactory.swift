import Foundation

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return .white
        }

        func disabledColor() -> UIColor {
            return UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            return UIColor.whiteFFFFFF30
        }
    }

    // MARK: - Light Background Color

    struct LightPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

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
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return .white
        }

        func disabledColor() -> UIColor {
            return UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            return UIColor.whiteFFFFFF30
        }
    }

    // MARK: - Dark Background Color

    struct DarkPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            return UIColor.green00C29A
        }

        func disabledColor() -> UIColor {
            return UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            return UIColor.green00C29A
        }
    }
}
