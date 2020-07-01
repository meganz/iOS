import UIKit

struct ButtonStatedStyle<T> {

    let stated: [ButtonState: T]

    enum ButtonState: Hashable, CaseIterable {
        case normal
        case highlighted
        case disabled

        var uiButtonState: UIButton.State {
            switch self {
            case .normal: return .normal
            case .highlighted: return .highlighted
            case .disabled: return .disabled
            }
        }
    }
}

// MARK: - TextStyle

extension ButtonStatedStyle where T == TextStyle {

    @discardableResult
    func applied(on button: UIButton) -> UIButton {
        button.setTitleColor(stated[.normal]?.color.uiColor, for: .normal)
        button.setTitleColor(stated[.highlighted]?.color.uiColor, for: .highlighted)
        button.setTitleColor(stated[.disabled]?.color.uiColor, for: .disabled)

        button.titleLabel?.font = stated[.normal]?.font.uiFont ??
            stated[.highlighted]?.font.uiFont ??
            stated[.disabled]?.font.uiFont
        return button
    }
}

// MARK: - ButtonStyle

extension ButtonStatedStyle where T == BackgroundStyle {

    @discardableResult
    func applied(on button: UIButton) -> UIButton {
        for buttonState in ButtonState.allCases {
            if let backgroundColor = stated[buttonState]?.backgroundColor.uiColor {
                button.setBackgroundColor(backgroundColor, for: buttonState.uiButtonState)
            }
        }
        return button
    }
}
