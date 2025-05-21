import Foundation
import MEGAAssets
import MEGADesignToken

struct LightColorThemeFactory: ColorFactory {
    
    func textColor(_ style: MEGAColor.Text) -> UIColor {
        switch style {
        case .primary: return TokenColors.Text.primary
        case .secondary: return TokenColors.Text.secondary
        case .tertiary: return TokenColors.Icon.secondary
        case .quaternary: return TokenColors.Icon.secondary
        case .warning: return TokenColors.Text.primary
        }
    }
    
    func backgroundColor(_ style: MEGAColor.Background) -> UIColor {
        switch style {
        case .primary, .secondary: return TokenColors.Background.page
        case .warning: return TokenColors.Notifications.notificationWarning
        case .enabled: return TokenColors.Support.success
        case .disabled: return MEGAAssets.UIColor.gray999999
        case .highlighted: return MEGAAssets.UIColor.green00A88680
            
        case .searchTextField: return MEGAAssets.UIColor.whiteEFEFEF
        case .homeTopSide: return TokenColors.Background.page
        }
    }
    
    func tintColor(_ style: MEGAColor.Tint) -> UIColor {
        switch style {
        case .primary: return TokenColors.Text.primary
        case .secondary: return TokenColors.Text.secondary
        }
    }
    
    func borderColor(_ style: MEGAColor.Border) -> UIColor {
        switch style {
        case .primary: return MEGAAssets.UIColor.black00000015
        case .warning: return TokenColors.Notifications.notificationWarning
        }
    }
    
    func shadowColor(_ style: MEGAColor.Shadow) -> UIColor {
        switch style {
        case .primary: return TokenColors.Text.primary
        }
    }
    
    func themeButtonTextFactory(_ style: MEGAColor.ThemeButton) -> any ButtonColorFactory {
        switch style {
        case .primary:
            return LightPrimaryThemeButtonTextColorFactory()
        case .secondary:
            return LightSecondaryThemeButtonTextColorFactory()
        }
    }
    
    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> any ButtonColorFactory {
        switch style {
        case .primary:
            return LightPrimaryThemeButtonBackgroundColorFactory()
        case .secondary:
            return LightSecondaryThemeButtonBackgroundColorFactory()
        }
    }
    
    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> UIColor {
        switch style {
        case .warning: return backgroundColor(.warning)
        }
    }
}
