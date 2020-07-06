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

    func styler(of style: MEGALabelStyle) -> LabelStyler {
        labelStyler(theme, style)
    }
}

private let labelStyler: (InterfaceStyle, MEGALabelStyle) -> LabelStyler = { theme, style in
    createLabelStyleFactory(from: theme).styler(of: style)
}

private let buttonStyler: (InterfaceStyle, MEGAThemeButtonStyle) -> ButtonStyler = { theme, style in
    createThemeButtonStyleFactory(from: theme).styler(of: style)
}

private let customStyler: (InterfaceStyle, MEGACustomViewStyle) -> ViewStyler = { theme, style in
    createCustomViewStyleFactory(from: theme).styler(of: style)
}

private let attributeTextStyler: (InterfaceStyle, AttributedTextStyle) -> TextAttributesStyler = { theme, style in
    createAttributedTextStyleFactory(from: theme).styler(of: style)
}
