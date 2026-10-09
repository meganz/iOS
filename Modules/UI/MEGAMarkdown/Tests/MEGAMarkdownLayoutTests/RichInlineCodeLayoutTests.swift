import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// The height and the first baseline of a row with inline code.
// The test that types plain text after code needs the focus. It is in `RichTextRowFocusTests`.
@MainActor
struct RichInlineCodeLayoutTests {
    /// The y of the baseline of the glyph, in the text view.
    private func baseline(of textView: RichTextView, glyph: Int) -> CGFloat {
        let manager = textView.layoutManager
        manager.ensureLayout(for: textView.textContainer)
        let line = manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        return line.minY + manager.location(forGlyphAt: glyph).y
    }

    /// Figma: a line with inline code is as tall as the chip. Wrapped lines have the line gap between them.
    @Test func aRowWithCodeHasChipHighLinesAndAGapBetweenThem() throws {
        let resolved = MarkdownTheme.default.resolved(for: UITraitCollection(preferredContentSizeCategory: .large))
        let short = RichTextRowHarness(blocks: [paragraph("ab", (0..<2, .code))])
        defer { short.close() }
        let long = String(repeating: "ab", count: 100)
        let wrapped = RichTextRowHarness(blocks: [paragraph(long, (0..<long.utf16.count, .code))])
        defer { wrapped.close() }
        let shortView = try #require(short.textView)
        let wrappedView = try #require(wrapped.textView)
        #expect(abs(shortView.fittingSize(width: 300).height - resolved.inlineCodeChipHeight) < 0.5)
        let wrappedHeight = wrappedView.fittingSize(width: 300).height
        let lines = ((wrappedHeight + resolved.inlineCodeLineGap) / (resolved.inlineCodeChipHeight + resolved.inlineCodeLineGap)).rounded()
        #expect(lines > 1)
        #expect(abs(wrappedHeight - (lines * resolved.inlineCodeChipHeight + (lines - 1) * resolved.inlineCodeLineGap)) < 0.5)
    }

    /// The list marker lines up with this value, so it must be where the text really puts its first baseline.
    @Test(arguments: [
        paragraph("a b", (2..<3, .code)),
        paragraph("a b"),
        paragraph("ab", (0..<2, .code))
    ])
    func theFirstBaselineFormulaMatchesTheLayout(block: RichBlock) throws {
        let harness = RichTextRowHarness(blocks: [block])
        defer { harness.close() }
        let textView = try #require(harness.textView)
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        let expected = RichTextRow.firstBaseline(of: block, theme: .default, traits: traits)
        #expect(abs(baseline(of: textView, glyph: 0) - expected) < 0.5, "layout \(baseline(of: textView, glyph: 0)), formula \(expected)")
    }
}
