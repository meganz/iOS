import Foundation

struct LightColorThemeFactory: ColorFactory {
    
    func textColor(_ style: MEGAColor.Text) -> UIColor {
        switch style {
        case .primary: return UIColor.black00000032
        case .secondary: return UIColor.gray999999
        case .tertiary: return UIColor.gray515151
        case .quaternary: return UIColor.gray848484
        case .warning: return UIColor.redFF3B30
        }
    }
    
    func backgroundColor(_ style: MEGAColor.Background) -> UIColor {
        switch style {
        case .primary: return .white
        case .secondary: return UIColor.grayC4CCCC
            
        case .warning: return UIColor.yellowFFCC0003
        case .enabled: return UIColor.green00A886
        case .disabled: return UIColor.gray999999
        case .highlighted: return UIColor.green00A88680
            
        case .searchTextField: return UIColor.grayE8E8E8
        case .homeTopSide: return UIColor.whiteF7F7F7
        }
    }
    
    func tintColor(_ style: MEGAColor.Tint) -> UIColor {
        switch style {
        case .primary: return UIColor.gray515151
        case .secondary: return UIColor.grayC4C4C4
        }
    }
    
    func borderColor(_ style: MEGAColor.Border) -> UIColor {
        switch style {
        case .primary: return UIColor.black00000015
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
