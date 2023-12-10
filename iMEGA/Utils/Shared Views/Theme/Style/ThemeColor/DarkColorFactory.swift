import Foundation

struct DarkColorThemeFactory: ColorFactory {
    func textColor(_ style: MEGAColor.Text) -> UIColor {
        switch style {
        case .primary: return UIColor.whiteFFFFFF32
        case .secondary: return MEGAAppColor.Gray._9B9B9B.uiColor
        case .tertiary: return MEGAAppColor.Gray._D1D1D1.uiColor
        case .quaternary: return MEGAAppColor.Gray._B5B5B5.uiColor
        case .warning: return UIColor.redFF453A
        }
    }
    
    func backgroundColor(_ style: MEGAColor.Background) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Black._1C1C1E.uiColor
        case .secondary: return MEGAAppColor.Gray._545A68.uiColor
        case .warning: return .white
        case .enabled: return UIColor.whiteFFD60008
        case .disabled: return MEGAAppColor.Gray._999999.uiColor
        case .highlighted: return UIColor.green00A88680
        case .searchTextField: return MEGAAppColor.Black._29292C.uiColor
        case .homeTopSide: return .black
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
        case .warning: return UIColor.yellowFFD600
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
