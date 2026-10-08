import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

@MainActor
@Suite struct RichTextStylerTests {
    private let resolved = MarkdownTheme.default.resolved(for: UITraitCollection(preferredContentSizeCategory: .large))

    private func styler(rightToLeft: Bool = false) -> RichTextStyler {
        RichTextStyler(resolved: resolved, isRightToLeft: rightToLeft)
    }

    @Test func piecesSplitAtEverySpanEdge() {
        let text = rich("abcdef", (0..<4, .bold), (2..<6, .italic))
        let pieces = RichTextStyler.pieces(of: text)
        #expect(pieces.map(\.range) == [0..<2, 2..<4, 4..<6])
        #expect(pieces.map(\.styles) == [[.bold], [.bold, .italic], [.italic]])
    }

    @Test func plainTextIsOnePiece() {
        let pieces = RichTextStyler.pieces(of: rich("abc"))
        #expect(pieces.count == 1)
        #expect(pieces.first?.range == 0..<3)
        #expect(pieces.first?.styles.isEmpty == true)
    }

    @Test func headingUsesTheThemeHeadingFont() throws {
        let text = styler().attributedString(heading(2, "Title"))
        let font = try #require(text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        #expect(font == resolved.headingFont(2))
    }

    @Test func inlineCodeGetsTheChipMark() {
        let text = styler().attributedString(paragraph("a code", (2..<6, .code)))
        #expect(text.attribute(.markdownInlineCode, at: 3, effectiveRange: nil) as? Bool == true)
        #expect(text.attribute(.markdownInlineCode, at: 0, effectiveRange: nil) == nil)
        #expect(text.attribute(.font, at: 3, effectiveRange: nil) as? UIFont == resolved.inlineCodeFont)
    }

    /// A link is colored and underlined, but has no `.link`: a tap must place the caret.
    @Test func linkIsLookOnly() {
        let text = styler().attributedString(paragraph("go", (0..<2, link("https://mega.nz"))))
        #expect(text.attribute(.link, at: 0, effectiveRange: nil) == nil)
        #expect(text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == resolved.linkColor)
        #expect(text.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int == NSUnderlineStyle.single.rawValue)
    }

    @Test func quoteTextUsesTheQuoteColor() {
        let text = styler().attributedString(quote("q"))
        #expect(text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == resolved.quoteTextColor)
    }

    /// Natural alignment follows the direction of each paragraph, like the preview. Code stays left.
    @Test(arguments: [false, true])
    func textAlignsByItsOwnDirectionButCodeStaysLeft(rightToLeft: Bool) {
        let alignment = { (block: RichBlock) in
            (styler(rightToLeft: rightToLeft).attributedString(block).attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.alignment
        }
        #expect(alignment(paragraph("a")) == .natural)
        #expect(alignment(paragraph("مرحبا")) == .natural)
        #expect(alignment(.codeBlock(language: nil, code: "a")) == .left)
    }

    @Test func codeRowsUseTheCodeFont() {
        let text = styler().attributedString(.codeBlock(language: nil, code: "let a"))
        #expect(text.string == "let a")
        #expect(text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont == resolved.codeFont)
    }
}
