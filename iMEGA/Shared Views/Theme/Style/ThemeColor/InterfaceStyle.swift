import Foundation

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

extension UITraitCollection {
    
    func backgroundStyler(of style: MEGAColor.Background) -> ViewStyler  {
        let theme = self.theme
        return { view in
            view.backgroundColor = theme.colorFactory.backgroundColor(style).uiColor
        }
    }
}

// MARK: - Special Alwyas Bright Label Style

extension UITraitCollection {

    func alwaysBrightLabelStyler(of style: MEGALabelStyle) -> LabelStyler  {
        theme.alwyasBrightLabelStyleFactory.styler(of: style)
    }
}
