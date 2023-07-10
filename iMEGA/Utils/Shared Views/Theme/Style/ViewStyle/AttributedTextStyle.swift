import UIKit

typealias AttributedTextStyler = (TextAttributes) -> TextAttributes

enum AttributedTextStyle {
    
    // MARK: - OverDiskQuota Warning Paragraph
    
    case paragraph
    case emphasized(MEGATextStyle)
    case warning
    
    static func composedStyler(from styles: [AttributedTextStyle],
                               of attributedTextStyleFactory: some AttributedTextStyleFactory
    ) -> AttributedTextStyler {
        return composedStyler(from: styles.map {
            attributedTextStyleFactory.styler(of: $0)
        })
    }

    static func composedStyler(from stylers: [AttributedTextStyler]) -> AttributedTextStyler {
        let initialStyler: AttributedTextStyler = { return $0 }
        return stylers.reduce(initialStyler) { (result, styler) in
            combine(result, styler)
        }
    }
}

private func combine(_ lhv: @escaping AttributedTextStyler,
                     _ rhv: @escaping AttributedTextStyler) -> AttributedTextStyler {
    return { attributes -> TextAttributes in
        return rhv(lhv(attributes))
    }
}
