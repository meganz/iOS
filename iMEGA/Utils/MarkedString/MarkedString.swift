import Foundation

@dynamicMemberLookup
/// A enum type to represent text with attributes.
enum MarkedString {
    /// Represent a string with `text` who is build inside tags and trailing child `MarkedString`.
    /// For example, *"<a>Hello</a>" is represented as `.text(tag: ["a"], text: "Hello", child: .end)`
    indirect case text(tag: [String], text: String, child: MarkedString)
    /// Represent the end of a `MarkedString`.
    case end
}

extension MarkedString {
    /// It's a subscription that to dynamically get enum `MarkedString`'s attatched objects - (tag, text and child).
    /// If `MarkedString` is `.end`, the return value is `nil`, if `MarkedString` is `.text` with `member` equals `values`, will return attached
    /// objects of the `.text` case. All other cases, `nil` will be returned.
    /// For example, while access `markedString.values`, if `markedString` is `.end`, `nil` will be returned.
    /// if `markedString` is `.text(["a"], "hello", .end)`, then return value would be a tuple with value `(["a"], "hello", .end)`
    public subscript(dynamicMember member: String) -> ([String], String, MarkedString)? {
        switch self {
        case .end: return nil
        case let .text(tag: tag, text: text, child: child) where member == "values":
            return (tag, text, child)
        default:
            return nil
        }
    }
}

extension MarkedString: Equatable {

    /// Test equality of two `MarkedString` object. Will return true if two `MarkedString` objects are both `.end` or `.text` when `.text`'s
    /// attached objects (tag, text, child) are equal.
    /// - Parameters:
    ///   - lhv: A `MarkedString` instance.
    ///   - rhv: A `MarkedString` instance.
    /// - Returns: `true` if provided `MarkedString` instance are equal, otherwise, false.
    public static func == (lhv: MarkedString, rhv: MarkedString) -> Bool {
        switch (lhv, rhv) {
        case (.end, .end):
            return true
        case let (.text(tag: lhTag, text: lhText, child: lhChild), .text(tag: rhTag, text: rhText, child: rhChild)):
            return lhTag == rhTag && lhText == rhText && lhChild == rhChild
        default:
            return false
        }
    }
}

extension MarkedString {
    
    /// Will return a `NSAttributedString` with provided `StyleMark` registration. Initially, current object's `tags` will be
    /// translated/mapped to `AttributedTextStyle`, then a `NSAttributedString` attributes array will be created. After that,
    /// a `NSAttributedString` will be created with current instance's text and newly created attributes. This function will recursively do the same process
    /// on to child instances too.
    ///
    /// NOTE: If current instance is `.end` or current instance's attached string `text` is *empty*, an empty `NSAttributedString` is returned.
    /// - Parameter styleMarks: It's, under the hood, a `Dictionary` with `Marker/Tag` as the key, and `AttributedTextStyle` as values.
    /// - Parameter attributedTextStyleFactory: Factory that could produce text styler with given text style
    /// - Returns: An attributed string with current instances's configurations - text, tags/styles, a
    func attributedString(withStyleMarks styleMarks: [String: AttributedTextStyle], attributedTextStyleFactory: some AttributedTextStyleFactory) -> NSAttributedString {
        switch self {
        case let .text(tag: tags, text: text, child: child):
            guard !text.isEmpty else {
                return child.attributedString(withStyleMarks: styleMarks, attributedTextStyleFactory: attributedTextStyleFactory)
            }

            let styles = tags.compactMap { styleMarks[$0] }
            let styler = AttributedTextStyle.composedStyler(from: styles, of: attributedTextStyleFactory)
            let textAttributes = styler(TextAttributes())

            let nodeAttributedString = NSMutableAttributedString(string: text, attributes: textAttributes)
            nodeAttributedString.append(child.attributedString(withStyleMarks: styleMarks, attributedTextStyleFactory: attributedTextStyleFactory))
            return nodeAttributedString
        case .end:
            return NSAttributedString()
        }
    }
}
