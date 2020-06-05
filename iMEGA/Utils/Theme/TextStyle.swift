import Foundation

struct TextStyle: Codable {
    let font: Font
    let color: Color
    var backgroundColor: Color = .init(red: 1, green: 1, blue: 1, alpha: 0)
}

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
    typealias TextAttributes = [NSAttributedString.Key: Any]
}

fileprivate func apply(style: TextStyle) -> (UILabel) -> UILabel {
    return { label in
        label.textColor = uiColor(from: style.color)
        label.font = uiFont(from: style.font)
        label.backgroundColor = uiColor(from: style.backgroundColor)
        return label
    }
}

fileprivate func apply(style: TextStyle) -> (UIButton) -> UIButton {
    return { button in
        button.setTitleColor(style.color.uiColor, for: .normal)
        button.titleLabel?.font = uiFont(from: style.font)
        return button
    }
}

fileprivate func apply(style: TextStyle) -> ([NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
    return { attributes in
        var copyAttributes = attributes
        copyAttributes[.font] = uiFont(from: style.font)
        copyAttributes[.foregroundColor] = uiColor(from: style.color)
        copyAttributes[.backgroundColor] = uiColor(from: style.backgroundColor)
        return copyAttributes
    }
}
