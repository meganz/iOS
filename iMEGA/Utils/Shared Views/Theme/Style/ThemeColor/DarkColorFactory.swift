import Foundation

struct DarkColorThemeFactory: ColorFactory {
    func textColor(_ style: MEGAColor.Text) -> UIColor {
        switch style {
        case .primary: return UIColor.whiteFFFFFF32
        case .secondary: return UIColor.gray9B9B9B
        case .tertiary: return UIColor.grayD1D1D1
        case .quaternary: return UIColor.grayB5B5B5
        case .warning: return UIColor.redFF453A
        }
    }
    
    func backgroundColor(_ style: MEGAColor.Background) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Black._1C1C1E.uiColor
        case .secondary: return UIColor.gray545A68
        case .warning: return .white
        case .enabled: return UIColor.whiteFFD60008
        case .disabled: return UIColor.gray999999
        case .highlighted: return UIColor.green00A88680
        case .searchTextField: return MEGAAppColor.Black._29292C.uiColor
        case .homeTopSide: return .black
        }
    }
    
    func tintColor(_ style: MEGAColor.Tint) -> UIColor {
        switch style {
        case .primary: return UIColor.grayD1D1D1
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
