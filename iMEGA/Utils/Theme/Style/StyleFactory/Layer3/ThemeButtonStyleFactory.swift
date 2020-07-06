import Foundation

extension InterfaceStyle {
    var themeButtonStyle: ThemeButtonStyleFactory {
        let colorFactory = createColorFactory(from: self)
        let cornerStyleFactory = createCornerStyleFactory()
        return ThemeButtonStyleFactoryImpl(colorFactory: colorFactory, cornerStyleFactory: cornerStyleFactory)
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

    func styler(of buttonStyle: MEGAThemeButtonStyle) -> ButtonStyler {
        let cornerStyleFactory = self.cornerStyleFactory
        switch buttonStyle {
        case .primary:
            return { button in
                cornerStyleFactory.cornerStyle(of: .round)
                    .applied(on: self.buttonBackgroundStyle(of: buttonStyle)
                        .applied(on: self.buttonTextStyle(of: buttonStyle)
                            .applied(on: button)))
            }
        case .secondary:
            return { button in
                cornerStyleFactory.cornerStyle(of: .round)
                    .applied(on: self.borderStyle(of: buttonStyle)
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
