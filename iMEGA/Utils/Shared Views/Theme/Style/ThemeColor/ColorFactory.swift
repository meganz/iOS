import Foundation

extension InterfaceStyle {

    var colorFactory: ColorFactory {
        switch self {
        case .light: return LightColorThemeFactory()
        case .dark: return DarkColorThemeFactory()
        }
    }
}

protocol ColorFactory {

    func textColor(_ style: MEGAColor.Text) -> ThemeColor

    func backgroundColor(_ style: MEGAColor.Background) -> ThemeColor

    func tintColor(_ style: MEGAColor.Tint) -> ThemeColor

    func borderColor(_ style: MEGAColor.Border) -> ThemeColor

    func shadowColor(_ style: MEGAColor.Shadow) -> ThemeColor

    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> ThemeColor

    // MARK: - Theme Button Factory

    func themeButtonTextFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory

    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory

    // MARK: - Independent

    func independent(_ style: MEGAColor.Independent) -> ThemeColor
}

extension ColorFactory {

    func independent(_ style: MEGAColor.Independent) -> ThemeColor {
        switch style {
        case .bright: return ThemeColor(red: 255, green: 255, blue: 255)
        case .dark: return ThemeColor(red: 0, green: 0, blue: 0)
        case .clear: return ThemeColor(red: 255, green: 255, blue: 255, alpha: 0)
        case .warning: return ThemeColor(red: 255, green: 59, blue: 48)
        }
    }
    
    func gradient(_ style: MEGAColor.Gradient) -> ThemeColor {
        switch style {
        case .exploreImagesStart:
            return ThemeColor(red: 249, green: 179, blue: 95)
        case .exploreImagesEnd:
            return ThemeColor(red: 230, green: 143, blue: 77)
            
        case .exploreDocumentsStart:
            return ThemeColor(red: 2, green: 162, blue: 255)
        case .exploreDocumentsEnd:
            return ThemeColor(red: 2, green: 116, blue: 204)
            
        case .exploreAudioStart:
            return ThemeColor(red: 0, green: 172, blue: 191)
        case .exploreAudioEnd:
            return ThemeColor(red: 0, green: 149, blue: 166)
            
        case .exploreVideoStart:
            return ThemeColor(red: 242, green: 136, blue: 194)
        case .exploreVideoEnd:
            return ThemeColor(red: 202, green: 117, blue: 209)
        }
    }
}
