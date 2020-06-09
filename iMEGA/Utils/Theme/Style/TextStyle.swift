import Foundation

struct TextStyle: Codable {
    let font: Font
    let color: Color
    var backgroundColor: Color? = nil
}

extension TextStyle {

    static var headlineTextStyle: TextStyle { TextStyle(font: .headline, color: .textDarkPrimary) }

    static var paragraphTextStyle: TextStyle { TextStyle(font: .subhead, color: .textDarkPrimary) }

    static var noteMainTextStyle: TextStyle { TextStyle(font: .caption1, color: .textDarkPrimary) }

    static var noteSubTextStyle: TextStyle { TextStyle(font: .caption2, color: .textDarkPrimary) }
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
}

fileprivate func apply(style: TextStyle) -> (UILabel) -> UILabel {
    return { label in
        label.textColor = style.color.uiColor
        label.font = style.font.uiFont
        label.backgroundColor = style.backgroundColor?.uiColor
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

typealias TextAttributes = [NSAttributedString.Key: Any]
fileprivate func apply(style: TextStyle) -> (TextAttributes) -> TextAttributes {
    return { attributes in
        var copyAttributes = attributes
        copyAttributes[.font] = uiFont(from: style.font)
        copyAttributes[.foregroundColor] = style.color.uiColor
        copyAttributes[.backgroundColor] = style.backgroundColor?.uiColor
        return copyAttributes
    }
}
