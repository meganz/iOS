import Foundation
import MEGADesignToken

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            TokenColors.Support.success
        }

        func disabledColor() -> UIColor {
            UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            TokenColors.Support.success
        }
    }

    // MARK: - Light Background Color

    struct LightSecondaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            UIColor.whiteFFFFFF
        }

        func disabledColor() -> UIColor {
            UIColor.whiteFFFFFF
        }

        func highlightedColor() -> UIColor {
            UIColor.whiteFFFFFF
        }
    }
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkSecondaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            TokenColors.Support.success
        }

        func disabledColor() -> UIColor {
            UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            UIColor.green00C29A4D
        }
    }

    // MARK: - Dark Background Color

    struct DarkSecondaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            UIColor.black363638
        }

        func disabledColor() -> UIColor {
            UIColor.whiteFFFFFF
        }

        func highlightedColor() -> UIColor {
            UIColor.whiteFFFFFF
        }
    }
}
