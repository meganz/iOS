import Foundation

struct DarkColorThemeFactory: ColorFactory {
    func textColor(_ style: MEGAColor.Text) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.White._FFFFFF32.uiColor
        case .secondary: return MEGAAppColor.Gray._9B9B9B.uiColor
        case .tertiary: return MEGAAppColor.Gray._D1D1D1.uiColor
        case .quaternary: return MEGAAppColor.Gray._B5B5B5.uiColor
        case .warning: return MEGAAppColor.Red._FF453A.uiColor
        }
    }
    
    func backgroundColor(_ style: MEGAColor.Background) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Black._1C1C1E.uiColor
        case .secondary: return MEGAAppColor.Gray._545A68.uiColor
        case .warning: return MEGAAppColor.White._FFFFFF.uiColor
        case .enabled: return MEGAAppColor.White._FFD60008.uiColor
        case .disabled: return MEGAAppColor.Gray._999999.uiColor
        case .highlighted: return MEGAAppColor.Green._00A88680.uiColor
        case .searchTextField: return MEGAAppColor.Black._29292C.uiColor
        case .homeTopSide: return MEGAAppColor.Black._000000.uiColor
        }
    }
    
    func tintColor(_ style: MEGAColor.Tint) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Gray._D1D1D1.uiColor
        case .secondary: return MEGAAppColor.Black._404040.uiColor
        }
    }
    
    func borderColor(_ style: MEGAColor.Border) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Black._00000015.uiColor
        case .warning: return MEGAAppColor.Yellow._FFD600.uiColor
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
            return DarkPrimaryThemeButtonTextColorFactory()
        case .secondary:
            return DarkSecondaryThemeButtonTextColorFactory()
        }
    }
    
    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> any ButtonColorFactory {
        switch style {
        case .primary:
            return DarkPrimaryThemeButtonBackgroundColorFactory()
        case .secondary:
            return DarkSecondaryThemeButtonBackgroundColorFactory()
        }
    }
    
    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> UIColor {
        switch style {
        case .warning: return backgroundColor(.warning)
        }
    }
}
