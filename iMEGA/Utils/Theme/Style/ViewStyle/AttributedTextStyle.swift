import UIKit

typealias TextAttributesStyler = (TextAttributes) -> TextAttributes

enum AttributedTextStyle {
    case paragraph
    case emphasized
    case warning

    var style: TextAttributesStyler {
        switch self {
        case .paragraph: return paragraphTextAttributesStyler
        case .emphasized: return emphasizedTextAttributesStyler
        case .warning: return warningTextAttributesStyler
        }
    }

    static func composedStyler(from styles: [AttributedTextStyle]) -> TextAttributesStyler {
        return composedStyler(from: styles.map(\.style))
    }

    static func composedStyler(from stylers: [TextAttributesStyler]) -> TextAttributesStyler {
        let initialStyler: TextAttributesStyler = { return $0 }
        return stylers.reduce(initialStyler) { (result, styler) in
            combine(result, styler)
        }
    }
}

fileprivate let paragraphTextAttributesStyler: TextAttributesStyler = { attributes in
    ParagraphStyle.centerAlignedWideSpacingParagraphStyle.applied(on:
        TextStyle.paragraphTextStyle.applied(on: attributes))
}

fileprivate let warningTextAttributesStyler: TextAttributesStyler = { attributes in
    TextStyle.warningTextStyle.applied(on:
        TextStyle.emphasizedTextStyle.applied(on: attributes))
}

fileprivate let emphasizedTextAttributesStyler: TextAttributesStyler = { attributes in
    TextStyle.emphasizedTextStyle.applied(on: attributes)
}

private func combine(_ lhv: @escaping TextAttributesStyler,
                     _ rhv: @escaping TextAttributesStyler) -> TextAttributesStyler {
    return { attributes -> TextAttributes in
        return rhv(lhv(attributes))
    }
}
