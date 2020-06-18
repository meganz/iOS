import Foundation

struct ParagraphStyle: Codable {
    var lineBreakMode: LineBreakMode = .wordWrapping
    var lineSpacing: LineSpacing = 1
    var paragraphSpacing: ParagraphSpacing = 1
    var alignment: TextAlignment = .natural

    typealias LineSpacing = CGFloat
    typealias ParagraphSpacing = CGFloat
}

// MARK: - Constant

extension ParagraphStyle {

    static var centerAlignedWideSpacingParagraphStyle: ParagraphStyle { .init(lineSpacing: 8, alignment: .center) }

    static var multilineWordWrappingNaturalAlignedParagraphStyle: ParagraphStyle {
        .init(lineBreakMode: .wordWrapping, alignment: .natural)
    }
}

extension ParagraphStyle {

    @discardableResult
    func applied(on label: UILabel) -> UILabel {
        apply(style: self)(label)
    }

    @discardableResult
    func applied(on textAttributes: TextAttributes) -> TextAttributes {
        apply(style: self)(textAttributes)
    }
}

enum LineBreakMode: String, Codable {
    case wordWrapping
    case charWrapping
    case clipping
    case truncateTail
    case truncateMiddle
    case truncateHead
}

fileprivate extension LineBreakMode {

    var nsLineBreakMode: NSLineBreakMode {
        switch self {
        case .charWrapping: return .byCharWrapping
        case .clipping: return .byClipping
        case .truncateHead: return .byTruncatingHead
        case .truncateMiddle: return .byTruncatingMiddle
        case .truncateTail: return .byTruncatingTail
        case .wordWrapping: return .byWordWrapping
        }
    }
}

enum TextAlignment: String, Codable {
    case left
    case right
    case center
    case justified
    case natural
}

fileprivate extension TextAlignment {

    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .center: return .center
        case .left: return .left
        case .right: return .right
        case .justified: return .justified
        case .natural: return .natural
        }
    }
}

fileprivate func apply(style: ParagraphStyle) -> (TextAttributes) -> TextAttributes {
    return { attributes in
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = style.alignment.nsTextAlignment
        paragraphStyle.lineBreakMode = style.lineBreakMode.nsLineBreakMode
        paragraphStyle.lineSpacing = style.lineSpacing
        paragraphStyle.paragraphSpacing = style.paragraphSpacing

        var copyAttributes = attributes
        copyAttributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        return copyAttributes
    }
}

fileprivate func apply(style: ParagraphStyle) -> (UILabel) -> UILabel {
    return { label in
        label.textAlignment = style.alignment.nsTextAlignment
        label.lineBreakMode = style.lineBreakMode.nsLineBreakMode
        label.numberOfLines = 0
        assert(style.lineSpacing == 1, "UILabel does not support lineSpacing \(style.lineSpacing)")
        assert(style.paragraphSpacing == 1, "UILabel does not support paragraphSpacing \(style.lineSpacing)")
        return label
    }
}
