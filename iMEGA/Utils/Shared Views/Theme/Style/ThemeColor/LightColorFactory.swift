import Foundation
import MEGADesignToken

struct LightColorThemeFactory: ColorFactory {
    
    func textColor(_ style: MEGAColor.Text) -> UIColor {
        switch style {
        case .primary: return TokenColors.Text.primary
        case .secondary: return TokenColors.Text.secondary
        case .tertiary: return MEGAAppColor.Gray._515151.uiColor
        case .quaternary: return MEGAAppColor.Gray._848484.uiColor
        case .warning: return TokenColors.Text.primary
        }
    }
    
    func backgroundColor(_ style: MEGAColor.Background) -> UIColor {
        switch style {
        case .primary, .secondary: return TokenColors.Background.page
        case .warning: return TokenColors.Notifications.notificationWarning
        case .enabled: return MEGAAppColor.Green._00A886.uiColor
        case .disabled: return MEGAAppColor.Gray._999999.uiColor
        case .highlighted: return MEGAAppColor.Green._00A88680.uiColor
            
        case .searchTextField: return MEGAAppColor.White._EFEFEF.uiColor
        case .homeTopSide: return MEGAAppColor.White._F7F7F7.uiColor
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
        case .primary: return MEGAAppColor.Black._00000015.uiColor
        case .warning: return TokenColors.Notifications.notificationWarning
        }
    }
    
    func shadowColor(_ style: MEGAColor.Shadow) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Black._000000.uiColor
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
