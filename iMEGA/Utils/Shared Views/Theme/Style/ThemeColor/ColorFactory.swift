import Foundation

extension InterfaceStyle {
    
    var colorFactory: any ColorFactory {
        switch self {
        case .light: return LightColorThemeFactory()
        case .dark: return DarkColorThemeFactory()
        }
    }
}

protocol ColorFactory {
    
    func textColor(_ style: MEGAColor.Text) -> UIColor
    
    func backgroundColor(_ style: MEGAColor.Background) -> UIColor
    
    func tintColor(_ style: MEGAColor.Tint) -> UIColor
    
    func borderColor(_ style: MEGAColor.Border) -> UIColor
    
    func shadowColor(_ style: MEGAColor.Shadow) -> UIColor
    
    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> UIColor
    
    // MARK: - Theme Button Factory
    
    func themeButtonTextFactory(_ style: MEGAColor.ThemeButton) -> any ButtonColorFactory
    
    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> any ButtonColorFactory
    
    // MARK: - Independent
    
    func independent(_ style: MEGAColor.Independent) -> UIColor
}

extension ColorFactory {
    
    func independent(_ style: MEGAColor.Independent) -> UIColor {
        switch style {
        case .bright: return .white
        case .dark: return .black
        case .clear: return MEGAAppColor.White._FFFFFF00.uiColor
        case .warning: return MEGAAppColor.Red._FF3B30.uiColor
        }
    }
    
    func gradient(_ style: MEGAColor.Gradient) -> UIColor {
        switch style {
        case .exploreImagesStart:
            return UIColor.orangeF9B35F
        case .exploreImagesEnd:
            return UIColor.orangeE68F4D
            
        case .exploreDocumentsStart:
            return MEGAAppColor.Blue._02A2FF.uiColor
        case .exploreDocumentsEnd:
            return MEGAAppColor.Blue._0274CC.uiColor
            
        case .exploreAudioStart:
            return MEGAAppColor.Blue._00ACBF.uiColor
        case .exploreAudioEnd:
            return MEGAAppColor.Blue._0095A6.uiColor
            
        case .exploreVideoStart:
            return MEGAAppColor.Red._F288C2.uiColor
        case .exploreVideoEnd:
            return MEGAAppColor.Red._CA75D1.uiColor
        }
    }
}
