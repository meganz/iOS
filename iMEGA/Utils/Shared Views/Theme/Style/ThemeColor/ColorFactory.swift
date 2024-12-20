import Foundation
import MEGADesignToken

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
        case .bright: return TokenColors.Text.onColor
        case .dark: return TokenColors.Text.primary
        case .clear: return UIColor.whiteFFFFFF00
        case .warning: return UIColor.redFF3B30
        }
    }
    
    func gradient(_ style: MEGAColor.Gradient) -> UIColor {
        switch style {
        case .exploreImagesStart:
            return UIColor.orangeF9B35F
        case .exploreImagesEnd:
            return UIColor.orangeE68F4D
        case .exploreDocumentsStart:
            return UIColor.blue02A2FF
        case .exploreDocumentsEnd:
            return UIColor.blue0274CC
        case .exploreAudioStart:
            return UIColor.blue00ACBF
        case .exploreAudioEnd:
            return UIColor.blue0095A6
        case .exploreVideoStart:
            return UIColor.redF288C2
        case .exploreVideoEnd:
            return UIColor.redCA75D1
        }
    }
}
