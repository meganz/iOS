import Foundation

extension InterfaceStyle {

    var buttonStyle: some ButtonStyleFactory {
        return ButtonStyleFactoryImpl(colorFactory: colorFactory,
                                      textStyleFactory: textStyleFactory)
    }
}

enum LegacyMEGAButtonStyle {
    case segmentTitleButton
    case searchControllerCancel
}

protocol ButtonStyleFactory {

    func styler(of buttonStyle: LegacyMEGAButtonStyle) -> ButtonStyler
}

private struct ButtonStyleFactoryImpl: ButtonStyleFactory {
    let colorFactory: any ColorFactory
    let textStyleFactory: any TextStyleFactory

    func styler(of buttonStyle: LegacyMEGAButtonStyle) -> ButtonStyler {

        switch buttonStyle {
        case .segmentTitleButton:
            return { button in
                self.buttonTextStyle(of: buttonStyle)
                    .applied(on: self.buttonBackgroundStyle(of: buttonStyle)
                        .applied(on: self.buttonColorStyle(of: buttonStyle)
                            .applied(on: button)))
            }

        case .searchControllerCancel:
            return { button in
                self.buttonTextStyle(of: buttonStyle)
                    .applied(on: self.buttonBackgroundStyle(of: buttonStyle)
                        .applied(on: self.buttonColorStyle(of: buttonStyle)
                            .applied(on: button)))
            }
        }
    }

    func buttonColorStyle(of buttonStyle: LegacyMEGAButtonStyle) -> ButtonStatedStyle<ColorStyle> {
        switch buttonStyle {
        case .segmentTitleButton:
            let normalTextColor = colorFactory.textColor(.secondary).asTextColorStyle
            let selectedTextColor = colorFactory.textColor(.primary).asTextColorStyle
            return ButtonStatedStyle<ColorStyle>(stated: [
                .normal: normalTextColor,
                .selected: selectedTextColor,
                .highlighted: selectedTextColor
            ])
        case .searchControllerCancel:
            let normalTextColor = colorFactory.textColor(.tertiary).asTextColorStyle
            return ButtonStatedStyle<ColorStyle>(stated: [
                .normal: normalTextColor
            ])
        }
    }

    func buttonTextStyle(of buttonStyle: LegacyMEGAButtonStyle) -> ButtonStatedStyle<TextStyle> {
        switch buttonStyle {
        case .segmentTitleButton:
            return ButtonStatedStyle<TextStyle>(stated: [
                .normal: textStyleFactory.textStyle(of: .subheadlineBold),
                .highlighted: textStyleFactory.textStyle(of: .headlineBold),
                .selected: textStyleFactory.textStyle(of: .headlineBold)
            ])
        case .searchControllerCancel:
            return ButtonStatedStyle<TextStyle>(stated: [
                .normal: textStyleFactory.textStyle(of: .body),
                .selected: textStyleFactory.textStyle(of: .body)
            ])
        }
    }

    func buttonBackgroundStyle(of buttonStyle: LegacyMEGAButtonStyle) -> ButtonStatedStyle<ColorStyle> {
        switch buttonStyle {
        case .segmentTitleButton:
            let clearColor = colorFactory.independent(.clear).asBackgroundColorStyle
            return ButtonStatedStyle<ColorStyle>(stated: [
                .normal: clearColor,
                .selected: clearColor,
                .highlighted: clearColor
            ])
        case .searchControllerCancel:
            let clearColor = colorFactory.independent(.clear).asBackgroundColorStyle
            return ButtonStatedStyle<ColorStyle>(stated: [
                .normal: clearColor,
                .selected: clearColor,
                .highlighted: clearColor
            ])
        }
    }
}
