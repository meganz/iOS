import UIKit

enum ButtonState: Hashable, CaseIterable {
    case normal
    case highlighted
    case disabled
    case selected

    var uiButtonState: UIButton.State {
        switch self {
        case .normal: return .normal
        case .highlighted: return .highlighted
        case .disabled: return .disabled
        case .selected: return .selected
        }
    }
}

struct ButtonStatedStyle<T> {

    let stated: [ButtonState: T]
}

// MARK: - TextStyle

extension ButtonStatedStyle where T == ColorStyle {

    @discardableResult
    func applied(on button: UIButton) -> UIButton {
        stated[.normal]?.applied(on: button, state: .normal)
        stated[.highlighted]?.applied(on: button, state: .highlighted)
        stated[.disabled]?.applied(on: button, state: .disabled)
        stated[.selected]?.applied(on: button, state: .selected)
        return button
    }
}

extension ButtonStatedStyle where T == TextStyle {

    @discardableResult
    func applied(on button: UIButton) -> UIButton {
        var textColor: TextStyle?
        if button.isSelected {
            textColor = stated[.selected]
        } else if button.isHighlighted {
            textColor = stated[.highlighted]
        } else if !button.isEnabled {
            textColor = stated[.disabled]
        }
        button.titleLabel?.font = (textColor ?? stated[.normal])?.font.value
        return button
    }
}

// MARK: - ButtonStyle

extension ButtonStatedStyle where T == BackgroundStyle {

    @discardableResult
    func applied<Button: UIButton>(on button: Button) -> Button {
        if let megaButton = (button as? (any ButtonBackgroundStateAware)) {
            for buttonState in ButtonState.allCases {
                if let backgroundColor = stated[buttonState]?.backgroundColor.uiColor {
                    megaButton.setBackgroundColor(backgroundColor, for: buttonState.uiButtonState)
                }
            }
        } else {
            for buttonState in ButtonState.allCases {
                if let backgroundColor = stated[buttonState]?.backgroundColor.uiColor {
                    button.setBackgroundColorImage(backgroundColor, for: buttonState.uiButtonState)
                }
            }
        }
        return button
    }
}
