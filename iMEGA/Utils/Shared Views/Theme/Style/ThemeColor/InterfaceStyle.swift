import Foundation

@MainActor
enum InterfaceStyle {
    case light
    case dark
}

extension UITraitCollection {

    var theme: InterfaceStyle {
        switch userInterfaceStyle {
        case .light: return .light
        case .dark: return .dark
        default: return .light
        }
    }
}

@MainActor
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

    func styler(of style: AttributedTextStyle) -> AttributedTextStyler {
        theme.attributedTextStyleFactory.styler(of: style)
    }
}

@MainActor
extension UITraitCollection {
    
    func backgroundStyler(of style: MEGAColor.Background) -> ViewStyler {
        let theme = self.theme
        return { view in
            view.backgroundColor = theme.colorFactory.backgroundColor(style)
        }
    }
}

// MARK: - Special Alwyas Bright Label Style

@MainActor
extension UITraitCollection {

    func alwaysBrightLabelStyler(of style: MEGALabelStyle) -> LabelStyler {
        theme.alwyasBrightLabelStyleFactory.styler(of: style)
    }
}
