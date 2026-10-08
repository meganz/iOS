import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. Plain text typed after inline code must not move the code text or change the row height.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichInlineCodeLayoutTests {
    /// The y of the baseline of the glyph, in the text view.
    private func baseline(of textView: RichTextView, glyph: Int) -> CGFloat {
        let manager = textView.layoutManager
        manager.ensureLayout(for: textView.textContainer)
        let line = manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        return line.minY + manager.location(forGlyphAt: glyph).y
    }

    @Test(arguments: [
        paragraph("ab", (0..<2, .code)),
        .listItem(RichListItem(isOrdered: false), text: RichText("ab", spans: [RichSpan(range: 0..<2, style: .code)]))
    ])
    func plainTextAfterCodeKeepsTheCodeAndTheRowHeight(block: RichBlock) async throws {
        let harness = RichTextRowHarness(blocks: [block])
        defer { harness.close() }
        let textView = try #require(harness.textView)
        textView.becomeFirstResponder()
        try await harness.settle()
        textView.selectedRange = NSRange(location: 2, length: 0)
        let width: CGFloat = 300
        let heightBefore = textView.fittingSize(width: width).height
        let baselineBefore = baseline(of: textView, glyph: 0)

        harness.model.toggleStyle(.code)
        textView.onTypingStylesChange?()
        harness.type(" cd", into: textView)
        try await harness.settle()

        #expect(textView.text == "ab cd")
        #expect(abs(textView.fittingSize(width: width).height - heightBefore) < 0.5, "row height changed")
        #expect(abs(baseline(of: textView, glyph: 0) - baselineBefore) < 0.5, "code baseline moved")
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
