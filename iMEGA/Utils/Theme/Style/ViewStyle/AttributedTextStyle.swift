import UIKit

typealias TextAttributesStyler = (TextAttributes) -> TextAttributes

enum AttributedTextStyle {
    case paragraph
    case emphasized
    case warning

    static func composedStyler(from styles: [AttributedTextStyle],
                               of attributedTextStyleFactory: AttributedTextStyleFactory
    ) -> TextAttributesStyler {
        return composedStyler(from: styles.map {
            attributedTextStyleFactory.styler(of: $0)
        })
    }

    static func composedStyler(from stylers: [TextAttributesStyler]) -> TextAttributesStyler {
        let initialStyler: TextAttributesStyler = { return $0 }
        return stylers.reduce(initialStyler) { (result, styler) in
            combine(result, styler)
        }
    }
}

private func combine(_ lhv: @escaping TextAttributesStyler,
                     _ rhv: @escaping TextAttributesStyler) -> TextAttributesStyler {
    return { attributes -> TextAttributes in
        return rhv(lhv(attributes))
    }
}
