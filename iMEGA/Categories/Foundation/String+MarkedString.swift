import Foundation

typealias StyleMarks = [String: AttributedTextStyle]

extension String {

    /// This function parses a `Marked String` which is a simple text with *marked* custom tags, like HTML, which denotes a relative style within,
    /// to an attributed string with given `StyleMarks`.
    /// For example, with the given string text `Hello <b>World</b>!` and `StyleMark` as *["b": .emphasized]*, the return value will be
    /// an `NSAttributedString` with *Hello* as no style and *World* text with style `emphasized` which is a defined in `AttributedTextStyle`.
    ///
    /// If the provider string is marked with which is not provided in the parameter - `StyleMarks`, the mark will be ignored and no style will be applied to the
    /// marked text.
    ///
    /// - Parameter styleMarks: A `StyleMark` instance, in fact a dicitonary `[String: AttributedTextStyle]` which has marks as keys and
    /// styles as values.
    /// - Parameter attributedTextStyleFactory: Factory that could produce text styler with given text style
    /// - Returns: A `AttributedString` that has relavent text and styles composed together.
    func attributedString(with styleMarks: StyleMarks, attributedTextStyleFactory: AttributedTextStyleFactory) -> NSAttributedString {
        MarkedStringParser.parseAttributedString(from: self, withStyleMarks: styleMarks, attributedTextStyleFactory: attributedTextStyleFactory)
    }
}
