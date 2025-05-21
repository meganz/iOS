import Foundation
import MEGAAssets
import MEGADesignToken

extension LightColorThemeFactory {

    // MARK: - Light Text Color

    struct LightPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            MEGAAssets.UIColor.whiteFFFFFF
        }

        func disabledColor() -> UIColor {
            MEGAAssets.UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            MEGAAssets.UIColor.whiteFFFFFF30
        }
    }

    // MARK: - Light Background Color

    struct LightPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            TokenColors.Support.success
        }

        func disabledColor() -> UIColor {
            MEGAAssets.UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            TokenColors.Support.success
        }
    }
}

extension DarkColorThemeFactory {

    // MARK: - Dark Text Color

    struct DarkPrimaryThemeButtonTextColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            MEGAAssets.UIColor.whiteFFFFFF
        }

        func disabledColor() -> UIColor {
            MEGAAssets.UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            MEGAAssets.UIColor.whiteFFFFFF30
        }
    }

    // MARK: - Dark Background Color

    struct DarkPrimaryThemeButtonBackgroundColorFactory: ButtonColorFactory {

        func normalColor() -> UIColor {
            TokenColors.Support.success
        }

        func disabledColor() -> UIColor {
            MEGAAssets.UIColor.gray999999
        }

        func highlightedColor() -> UIColor {
            TokenColors.Support.success
        }
    }
}
