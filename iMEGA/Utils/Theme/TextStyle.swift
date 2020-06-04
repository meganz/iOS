import Foundation

struct TextStyle: Codable {
    let font: Font
    let color: Color
    var backgroundColor: Color = .init(red: 1, green: 1, blue: 1, alpha: 0)
}

extension TextStyle {

    var styleLabel: (UILabel) -> UILabel {
        return { label in
            apply(style: self)(label)
        }
    }

    typealias TextAttributes = [NSAttributedString.Key: Any]

    var styleTextAttributes: (TextAttributes) -> TextAttributes {
        return { attributes in
            apply(style: self)(attributes)
        }
    }
}

func apply(style: TextStyle) -> (UILabel) -> UILabel {
    return { label in
        label.textColor = uiColor(from: style.color)
        label.font = uiFont(from: style.font)
        label.backgroundColor = uiColor(from: style.backgroundColor)
        return label
    }
}

func apply(style: TextStyle) -> ([NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
    return { attributes in
        var copyAttributes = attributes
        copyAttributes[.font] = uiFont(from: style.font)
        copyAttributes[.foregroundColor] = uiColor(from: style.color)
        copyAttributes[.backgroundColor] = uiColor(from: style.backgroundColor)
        return copyAttributes
    }
}
