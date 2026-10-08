@testable import MEGAMarkdown
import Testing
import UIKit

@MainActor
@Suite struct InlineCodeTextTests {
    private func attributed(_ markdown: String) throws -> NSAttributedString {
        guard case .paragraph(let text) = try #require(parse(markdown).first).kind else {
            Issue.record("not a paragraph")
            return NSAttributedString()
        }
        let resolved = MarkdownTheme.default.resolved(for: UITraitCollection(userInterfaceStyle: .light))
        return InlineCodeText.attributedString(
            text,
            baseFont: resolved.bodyFont,
            color: .label,
            resolved: resolved,
            direction: .leftToRight
        )
    }

    /// The parser writes `<u>` as a SwiftUI attribute, not as an inline intent. The row must still underline it.
    @Test func underlineNextToInlineCodeStaysUnderlined() throws {
        let text = try attributed("<u>a</u> `b`")
        #expect(text.string == "a b")
        #expect(text.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int == NSUnderlineStyle.single.rawValue)
        #expect(text.attribute(.underlineStyle, at: 2, effectiveRange: nil) == nil)
    }
}
