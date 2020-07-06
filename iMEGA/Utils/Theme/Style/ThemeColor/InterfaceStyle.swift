import Foundation

enum InterfaceStyle {
    case light
    case dark
}

extension UITraitCollection {

    var theme: InterfaceStyle {
        if #available(iOS 12.0, *) {
            switch userInterfaceStyle {
            case .light: return .light
            case .dark: return .dark
            default: return .light
            }
        }
        return .light
    }
}

extension UITraitCollection {

    func styler(of style: MEGALabelStyle) -> LabelStyler {
        theme.labelStyleFactory.styler(of: style)
    }

    func styler(of style: MEGAThemeButtonStyle) -> ButtonStyler {
        theme.themeButtonStyle.styler(of: style)
    }

    func styler(of style: MEGACustomViewStyle) -> ViewStyler {
        theme.customViewStyleFactory.styler(of: style)
    }

    func styler(of style: AttributedTextStyle) -> TextAttributesStyler {
        theme.attributedTextStyleFactory.styler(of: style)
    }
}
