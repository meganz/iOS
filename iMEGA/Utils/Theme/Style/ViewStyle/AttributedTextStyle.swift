import UIKit

typealias TextAttributesStyler = (TextAttributes) -> TextAttributes

enum AttributedTextStyle {
    case paragraph

    var style: TextAttributesStyler {
        switch self {
        case .paragraph: return paragraphTextAttributesStyler
        }
    }
}

fileprivate let paragraphTextAttributesStyler: (TextAttributes) -> TextAttributes = { attributes in
    ParagraphStyle(lineSpacing: 8, alignment: .center)
        .applied(on: TextStyle.paragraphTextStyle.applied(on: attributes))

}
