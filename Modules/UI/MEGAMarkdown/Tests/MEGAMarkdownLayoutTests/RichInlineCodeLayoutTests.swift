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

    // MARK: - Hyphens

    private static let longCode = String(repeating: "long_code_span_", count: 30) + "end"
    private static let longCodeText = "A very long code span " + longCode + " in a paragraph."
    /// Where `longCode` sits in `longCodeText`, in UTF-16 units like `RichSpan`.
    private static let longCodeRange: Range<Int> = {
        let found = (longCodeText as NSString).range(of: longCode)
        return found.location..<NSMaxRange(found)
    }()

    /// A text view styled like a row and laid out `width` wide, without a window.
    private func styledTextView(_ block: RichBlock, width: CGFloat) -> RichTextView {
        let textView = RichTextView.make()
        let resolved = MarkdownTheme.default.resolved(for: UITraitCollection(preferredContentSizeCategory: .large))
        textView.attributedText = RichTextStyler(resolved: resolved, isRightToLeft: false).attributedString(block)
        textView.frame = CGRect(x: 0, y: 0, width: width, height: textView.fittingSize(width: width).height)
        textView.layoutIfNeeded()
        return textView
    }

    /// The lines and glyphs of the text view. An added hyphen is a glyph with no character.
    private func layout(of textView: RichTextView) -> (lines: Int, glyphs: Int) {
        let manager = textView.layoutManager
        manager.ensureLayout(for: textView.textContainer)
        var lines = 0
        manager.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: manager.numberOfGlyphs)) { _, _, _, _, _ in lines += 1 }
        return (lines, manager.numberOfGlyphs)
    }

    /// The glyphs of the same text in a plain layout manager with no delegate, so with no rule, at the same container size.
    private func glyphsWithoutTheRule(_ textView: RichTextView) -> Int {
        let manager = NSLayoutManager()
        let storage = NSTextStorage(attributedString: textView.attributedText)
        let container = NSTextContainer(size: textView.textContainer.size)
        container.lineFragmentPadding = 0
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        manager.ensureLayout(for: container)
        return manager.numberOfGlyphs
    }

    /// Code has no words. A hyphen at a break inside it reads as part of the code, so the line breaks with none.
    @Test(arguments: [120, 200, 294, 300, 410] as [CGFloat])
    func longCodeSpanWrapsWithoutAddedHyphens(width: CGFloat) {
        let textView = styledTextView(paragraph(Self.longCodeText, (Self.longCodeRange, .code)), width: width)
        let result = layout(of: textView)
        #expect(result.lines > 2)
        #expect(result.glyphs == textView.textStorage.length)
    }

    /// The system adds hyphens to the row's text without the rule, so the tests above check the rule and not the styling.
    @Test func longCodeSpanGetsHyphensFromTheSystemWithoutTheRule() {
        let textView = styledTextView(paragraph(Self.longCodeText, (Self.longCodeRange, .code)), width: 294)
        #expect(glyphsWithoutTheRule(textView) > textView.textStorage.length)
    }

    /// The same text in a real row, styled by `RichTextRow.Coordinator`.
    @Test func longCodeSpanInARowWrapsWithoutAddedHyphens() throws {
        let harness = RichTextRowHarness(blocks: [paragraph(Self.longCodeText, (Self.longCodeRange, .code))])
        defer { harness.close() }
        let textView = try #require(harness.textView)
        let result = layout(of: textView)
        #expect(result.lines > 2)
        #expect(result.glyphs == textView.textStorage.length)
    }

    /// The rule touches only breaks at code. A long plain word keeps the line breaks of a row without the rule.
    @Test func plainLongWordWrapsLikeATextViewWithoutTheRule() {
        let word = String(repeating: "Supercalifragilistic", count: 6)
        let block = paragraph("A code span then " + word + " after.", (2..<6, .code))
        for width in [160, 240, 320] as [CGFloat] {
            let textView = styledTextView(block, width: width)
            #expect(layout(of: textView).glyphs == glyphsWithoutTheRule(textView), "width \(width)")
        }
    }
}
