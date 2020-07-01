import Foundation

func createThemeButtonStyleFactory(from colorTheme: InterfaceStyle) -> ThemeButtonStyleFactory {
    let colorFactory = createColorFactory(from: colorTheme)
    return ThemeButtonStyleFactoryImpl(colorFactory: colorFactory)
}

typealias ButtonStyler = (UIButton) -> Void

enum MEGAThemeButtonStyle {
    case primary
    case secondary
}

protocol ThemeButtonStyleFactory {

    func buttonStyle(of buttonStyle: MEGAThemeButtonStyle) -> ButtonStyler

    func borderStyle(of borderStyle: MEGAThemeButtonStyle) -> BorderStyle

    func buttonTextStyle(of buttonStyle: MEGAThemeButtonStyle) -> ButtonStatedStyle<TextStyle>

    func buttonBackgroundStyle(of buttonStyle: MEGAThemeButtonStyle) -> ButtonStatedStyle<BackgroundStyle>
}

private struct ThemeButtonStyleFactoryImpl: ThemeButtonStyleFactory {

    let colorFactory: ColorFactory

    func buttonStyle(of buttonStyle: MEGAThemeButtonStyle) -> ButtonStyler {
        switch buttonStyle {
        case .primary:
            return { button in
                CornerStyle.roundCornerStyle
                    .applied(on: self.buttonBackgroundStyle(of: buttonStyle)
                        .applied(on: self.buttonTextStyle(of: buttonStyle)
                            .applied(on: button)))
            }
        case .secondary:
            return { button in
                CornerStyle.roundCornerStyle
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
