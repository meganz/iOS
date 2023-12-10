import Foundation

struct LightColorThemeFactory: ColorFactory {
    
    func textColor(_ style: MEGAColor.Text) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Black._00000032.uiColor
        case .secondary: return MEGAAppColor.Gray._999999.uiColor
        case .tertiary: return MEGAAppColor.Gray._515151.uiColor
        case .quaternary: return MEGAAppColor.Gray._848484.uiColor
        case .warning: return UIColor.redFF3B30
        }
    }
    
    func backgroundColor(_ style: MEGAColor.Background) -> UIColor {
        switch style {
        case .primary: return .white
        case .secondary: return MEGAAppColor.Gray._C4CCCC.uiColor
            
        case .warning: return UIColor.yellowFFCC0003
        case .enabled: return UIColor.green00A886
        case .disabled: return MEGAAppColor.Gray._999999.uiColor
        case .highlighted: return UIColor.green00A88680
            
        case .searchTextField: return UIColor.whiteEFEFEF
        case .homeTopSide: return UIColor.whiteF7F7F7
        }
    }
    
    func tintColor(_ style: MEGAColor.Tint) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Gray._515151.uiColor
        case .secondary: return MEGAAppColor.Gray._C4C4C4.uiColor
        }
    }
    
    func borderColor(_ style: MEGAColor.Border) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Black._00000015.uiColor
        case .warning: return UIColor.yellowFFCC00
        }
    }
    
    func shadowColor(_ style: MEGAColor.Shadow) -> UIColor {
        switch style {
        case .primary: return .black
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
