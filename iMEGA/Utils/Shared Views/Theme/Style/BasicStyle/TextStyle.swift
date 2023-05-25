import Foundation

struct TextStyle: Codable {
    let font: FontStyle
}

// MARK: - UI Applier

extension TextStyle {

    // MARK: - UILabel Applier

    @discardableResult
    func applied(on label: UILabel) -> UILabel {
        apply(style: self)(label)
    }

    // MARK: - UIButton Applier

    @discardableResult
    func applied(on button: UIButton) -> UIButton {
        apply(style: self)(button)
    }

    // MARK: - AttributedString Applier

    @discardableResult
    func applied(on attributes: TextAttributes) -> TextAttributes {
        apply(style: self)(attributes)
    }

    // MARK: - UILabel Applier

    @discardableResult
    func applied(on textField: UITextField) -> UITextField {
        apply(style: self)(textField)
    }
}

private func apply(style: TextStyle) -> (UILabel) -> UILabel {
    return { label in
        label.font = style.font.value
        return label
    }
}

private func apply(style: TextStyle) -> (UIButton) -> UIButton {
    return { button in
        button.titleLabel?.font = style.font.value
        return button
    }
}

typealias TextAttributes = [NSAttributedString.Key: Any]
private func apply(style: TextStyle) -> (TextAttributes) -> TextAttributes {
    return { attributes in
        var copyAttributes = attributes
        copyAttributes[.font] = style.font.value
        return copyAttributes
    }
}

private func apply(style: TextStyle) -> (UITextField) -> UITextField {
    return { textField in
        textField.font = style.font.value
        return textField
    }
}
