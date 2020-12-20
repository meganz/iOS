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

    func textColor(_ style: MEGAColor.Text) -> Color

    func backgroundColor(_ style: MEGAColor.Background) -> Color

    func tintColor(_ style: MEGAColor.Tint) -> Color

    func borderColor(_ style: MEGAColor.Border) -> Color

    func shadowColor(_ style: MEGAColor.Shadow) -> Color

    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> Color

    // MARK: - Theme Button Factory

    func themeButtonTextFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory

    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> ButtonColorFactory

    // MARK: - Independent

    func independent(_ style: MEGAColor.Independent) -> Color
}

extension ColorFactory {

    func independent(_ style: MEGAColor.Independent) -> Color {
        switch style {
        case .bright: return Color(red: 255, green: 255, blue: 255)
        case .dark: return Color(red: 0, green: 0, blue: 0)
        case .clear: return Color(red: 255, green: 255, blue: 255, alpha: 0)
        case .warning: return Color(red: 255, green: 59, blue: 48)
        }
    }
    
    func gradient(_ style: MEGAColor.Gradient) -> Color {
        switch style {
        case .exploreImagesStart:
            return Color(red: 249, green: 179, blue: 95)
        case .exploreImagesEnd:
            return Color(red: 230, green: 143, blue: 77)
            
        case .exploreDocumentsStart:
            return Color(red: 2, green: 162, blue: 255)
        case .exploreDocumentsEnd:
            return Color(red: 2, green: 116, blue: 204)
            
        case .exploreAudioStart:
            return Color(red: 0, green: 172, blue: 191)
        case .exploreAudioEnd:
            return Color(red: 0, green: 149, blue: 166)
            
        case .exploreVideoStart:
            return Color(red: 242, green: 136, blue: 194)
        case .exploreVideoEnd:
            return Color(red: 202, green: 117, blue: 209)
        }
    }
}
