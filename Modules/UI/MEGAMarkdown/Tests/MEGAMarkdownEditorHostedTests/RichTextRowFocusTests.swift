import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. One row with the focus. The typing style and a user caret move
// reach the row only while it is editing, so these tests cannot run in `MEGAMarkdownLayoutTests`.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichTextRowFocusTests {
    private func focusedTextView(_ harness: RichTextRowHarness, caret: Int) throws -> RichTextView {
        let textView = try #require(harness.textView)
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: caret, length: 0)
        return textView
    }

    /// The y of the baseline of the glyph, in the text view.
    private func baseline(of textView: RichTextView, glyph: Int) -> CGFloat {
        let manager = textView.layoutManager
        manager.ensureLayout(for: textView.textContainer)
        let line = manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        return line.minY + manager.location(forGlyphAt: glyph).y
    }

    /// A style turned off at the caret stays off for the next key.
    @Test func typingKeepsAStyleTurnedOffAtTheCaret() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("bold", (0..<4, .bold))])
        defer { harness.close() }
        let textView = try focusedTextView(harness, caret: 2)
        harness.model.select(.caret(position(0, 2)))
        harness.model.toggleStyle(.bold)
        textView.onTypingStylesChange?()
        harness.type("x", into: textView)
        #expect(harness.model.row(at: 0).block == paragraph("boxld", (0..<2, .bold), (3..<5, .bold)))
        let font = try #require(textView.attributedText.attribute(.font, at: 2, effectiveRange: nil) as? UIFont)
        #expect(!font.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    /// The link dialog takes the focus. When the row gets it back with the caret after the new link, typed text is plain.
    @Test func typingAfterASavedLinkIsPlain() async throws {
        let harness = RichTextRowHarness(blocks: [paragraph("")])
        defer { harness.close() }
        let textView = try focusedTextView(harness, caret: 0)
        harness.model.beginLinkEditing()
        textView.resignFirstResponder()
        #expect(harness.model.saveLink(urlText: "u", label: "go"))
        harness.reconfigure()
        try await harness.settle()
        textView.focusFromModel(selection: NSRange(location: 2, length: 0))
        harness.type("x", into: textView)
        #expect(harness.model.row(at: 0).block == paragraph("gox", (0..<2, .link(RichLink(destination: "u", title: "")))))
        #expect(textView.attributedText.attribute(.underlineStyle, at: 2, effectiveRange: nil) == nil)
    }

    @Test func userCaretMoveSelectsInTheModel() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abcd")])
        defer { harness.close() }
        let textView = try focusedTextView(harness, caret: 0)
        textView.selectedRange = NSRange(location: 1, length: 2)
        #expect(harness.model.selection == .range(1..<3, inBlock: 0))
    }

    /// Plain text typed after inline code must not move the code text or change the row height.
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
}
