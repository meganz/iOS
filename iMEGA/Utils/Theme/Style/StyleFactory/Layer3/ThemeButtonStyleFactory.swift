import Foundation

extension InterfaceStyle {

    var themeButtonStyle: ThemeButtonStyleFactory {
        return ThemeButtonStyleFactoryImpl(colorFactory: colorFactory,
                                           cornerStyleFactory: cornerStyleFactory,
                                           shadowStyleFactory: shadowStyleFactory)
    }
}

typealias ButtonStyler = (UIButton) -> Void

enum MEGAThemeButtonStyle {
    case primary
    case secondary
}

protocol ThemeButtonStyleFactory {

    func styler(of buttonStyle: MEGAThemeButtonStyle) -> ButtonStyler
}

private struct ThemeButtonStyleFactoryImpl: ThemeButtonStyleFactory {

    let colorFactory: ColorFactory

    let cornerStyleFactory: CornerStyleFactory

    let shadowStyleFactory: ShadowStyleFactory

    func styler(of buttonStyle: MEGAThemeButtonStyle) -> ButtonStyler {
        let cornerStyle = cornerStyleFactory.cornerStyle(of: .round)
        let primaryShadowColor = colorFactory.shadowColor(.primary)
        let themeButtonShadowStyle = shadowStyleFactory.shadowStyle(of: .themeButton(color: primaryShadowColor))

        switch buttonStyle {
        case .primary:
            return { button in
                themeButtonShadowStyle
                    .applied(on: cornerStyle
                            .applied(on: self.buttonTextStyle(of: buttonStyle)
                                .applied(on: self.buttonBackgroundStyle(of: buttonStyle)
                                    .applied(on: button))))
            }
        case .secondary:
            return { button in
                themeButtonShadowStyle
                    .applied(on: cornerStyle
                        .applied(on: self.buttonBackgroundStyle(of: buttonStyle)
                            .applied(on: self.buttonTextStyle(of: buttonStyle)
                                .applied(on: button))))
            }
        }
    }

    func borderStyle(of borderStyle: MEGAThemeButtonStyle) -> BorderStyle {
        switch borderStyle {
        case .primary:
            return BorderStyle(width: 1, color: colorFactory.borderColor(.primary))
        case .secondary:
            return BorderStyle(width: 1, color: colorFactory.borderColor(.primary))
        }
    }

    func buttonTextStyle(of buttonStyle: MEGAThemeButtonStyle) -> ButtonStatedStyle<TextStyle> {
        switch buttonStyle {
        case .primary:
            let themeButtonTextFactory = colorFactory.themeButtonTextFactory(.primary)
            return ButtonStatedStyle<TextStyle>(stated: [
                .normal: TextStyle(font: .headline, color: themeButtonTextFactory.normalColor()),
                .disabled: TextStyle(font: .headline, color: themeButtonTextFactory.disabledColor()),
                .highlighted: TextStyle(font: .headline, color: themeButtonTextFactory.highlightedColor())
            ])
        case .secondary:
            let themeButtonTextFactory = colorFactory.themeButtonTextFactory(.secondary)
            return ButtonStatedStyle<TextStyle>(stated: [
                .normal: TextStyle(font: .headline, color: themeButtonTextFactory.normalColor()),
                .disabled: TextStyle(font: .headline, color: themeButtonTextFactory.disabledColor()),
                .highlighted: TextStyle(font: .headline, color: themeButtonTextFactory.highlightedColor())
            ])
        }
    }

    func buttonBackgroundStyle(of buttonStyle: MEGAThemeButtonStyle) -> ButtonStatedStyle<BackgroundStyle> {
        switch buttonStyle {
        case .primary:
            let themeButtonBackgroundFactory = colorFactory.themeButtonBackgroundFactory(.primary)
            return ButtonStatedStyle<BackgroundStyle>(stated: [
                .normal: BackgroundStyle(backgroundColor: themeButtonBackgroundFactory.normalColor()),
                .disabled: BackgroundStyle(backgroundColor: themeButtonBackgroundFactory.disabledColor()),
                .highlighted: BackgroundStyle(backgroundColor: themeButtonBackgroundFactory.highlightedColor()),
            ])
        case .secondary:
            let themeButtonBackgroundFactory = colorFactory.themeButtonBackgroundFactory(.secondary)
            return  ButtonStatedStyle<BackgroundStyle>(stated: [
               .normal: BackgroundStyle(backgroundColor: themeButtonBackgroundFactory.normalColor()),
               .disabled: BackgroundStyle(backgroundColor: themeButtonBackgroundFactory.disabledColor()),
               .highlighted: BackgroundStyle(backgroundColor: themeButtonBackgroundFactory.highlightedColor()),
           ])
        }
    }
}
