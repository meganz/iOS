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

    /// SwiftUI can measure the view at the old width after a rotation. The text must still wrap at the view's width.
    @Test func measuringAtAnotherWidthKeepsTheDrawnLines() throws {
        let resolved = MarkdownTheme.default.resolved(for: UITraitCollection(userInterfaceStyle: .light))
        let view = InlineCodeTextView()
        view.configure(text: try attributed(String(repeating: "Some words and `code` ", count: 8)), baseFont: resolved.bodyFont, resolved: resolved)
        view.frame = CGRect(x: 0, y: 0, width: 300, height: view.height(forWidth: 300))
        view.layoutIfNeeded()
        let before = image(of: view)
        _ = view.height(forWidth: 800)
        #expect(image(of: view) == before)
    }

    // MARK: - Hyphens

    private static let longCode = "A very long code span `" + String(repeating: "long_code_span_", count: 30) + "end` in a paragraph."

    private func configuredView(_ markdown: String, width: CGFloat) throws -> InlineCodeTextView {
        let resolved = MarkdownTheme.default.resolved(for: UITraitCollection(userInterfaceStyle: .light))
        let view = InlineCodeTextView()
        view.configure(text: try attributed(markdown), baseFont: resolved.bodyFont, resolved: resolved)
        _ = view.height(forWidth: width)
        return view
    }

    /// The character ranges of the laid-out lines. An added hyphen is a glyph with no character.
    private func lines(of manager: NSLayoutManager) -> [NSRange] {
        var ranges: [NSRange] = []
        manager.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: manager.numberOfGlyphs)) { _, _, _, glyphs, _ in
            ranges.append(manager.characterRange(forGlyphRange: glyphs, actualGlyphRange: nil))
        }
        return ranges
    }

    /// The lines the system makes for `text` at `width`, with the same layout manager but no delegate.
    private func systemLines(of text: NSAttributedString, width: CGFloat) -> (lines: [NSRange], glyphs: Int) {
        let storage = NSTextStorage(attributedString: text)
        let manager = InlineCodeLayoutManager()
        manager.usesFontLeading = false
        let container = NSTextContainer(size: CGSize(width: width - 2 * InlineCodeTextView.inset, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        manager.ensureLayout(for: container)
        return (lines(of: manager), manager.numberOfGlyphs)
    }

    /// Code has no words. A hyphen at a break inside it reads as part of the code, so the line breaks with none.
    /// Widths from narrow to wide, so the breaks fall at different places in the code.
    @Test(arguments: [120, 200, 210, 300, 405, 410] as [CGFloat])
    func longCodeSpanWrapsWithoutAddedHyphens(width: CGFloat) throws {
        let view = try configuredView(Self.longCode, width: width)
        let manager = view.layoutManager
        #expect(lines(of: manager).count > 2)
        #expect(manager.numberOfGlyphs == manager.textStorage?.length)
    }

    /// The system adds hyphens here without the rule, so the test above checks the rule and not the font.
    @Test func longCodeSpanGetsHyphensFromTheSystemWithoutTheRule() throws {
        let system = systemLines(of: try attributed(Self.longCode), width: 200)
        #expect(system.glyphs > (try attributed(Self.longCode)).length)
    }

    /// Letters right after the code continue the same word. A break at the code's edge gets no hyphen either.
    @Test(arguments: [150, 200, 250] as [CGFloat])
    func wordThatContinuesAfterTheCodeWrapsWithoutAddedHyphens(width: CGFloat) throws {
        let markdown = "`" + String(repeating: "code_", count: 12) + "`" + String(repeating: "letters", count: 12)
        let manager = try configuredView(markdown, width: width).layoutManager
        #expect(manager.numberOfGlyphs == manager.textStorage?.length)
    }

    /// The rule touches only breaks at code. Text without a break at code wraps where the system wraps it,
    /// a long plain word keeps the system's hyphen, and so does Vietnamese and right-to-left text.
    @Test(arguments: [
        String(repeating: "Some words and `code` with more plain text. ", count: 8),
        "A `code` span and a long plain word " + String(repeating: "Supercalifragilistic", count: 6) + " after it.",
        "Tiếng Việt có dấu, một đoạn văn dài hơn một dòng với `mã` ở giữa và nhiều chữ nữa ở cuối.",
        "טקסט בעברית עם `code` באמצע, ועוד מילים כדי שהשורה תתפצל לשתי שורות לפחות."
    ])
    func textWithoutBreaksAtCodeWrapsLikeTheSystem(markdown: String) throws {
        for width in [160, 240, 320] as [CGFloat] {
            let manager = try configuredView(markdown, width: width).layoutManager
            let system = systemLines(of: try attributed(markdown), width: width)
            #expect(lines(of: manager) == system.lines, "width \(width)")
            #expect(manager.numberOfGlyphs == system.glyphs, "width \(width)")
        }
    }

    /// Every line of text with inline code stays as tall as the chip, also when long code wraps.
    @Test func wrappedCodeKeepsChipHighLines() throws {
        let resolved = MarkdownTheme.default.resolved(for: UITraitCollection(userInterfaceStyle: .light))
        let manager = try configuredView(Self.longCode, width: 200).layoutManager
        var heights: Set<CGFloat> = []
        manager.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: manager.numberOfGlyphs)) { rect, _, _, _, _ in
            heights.insert(rect.height)
        }
        #expect(heights.count == 1, "\(heights)")
        #expect(abs((heights.first ?? 0) - (resolved.inlineCodeChipHeight + resolved.inlineCodeLineGap)) < 0.5)
    }

    /// The rule reads the code attribute on both sides of the break, and allows a hyphen anywhere else.
    @Test func hyphenIsRefusedOnlyNextToCode() throws {
        // The manager reads the code attribute when the text is set, as in the views.
        let storage = NSTextStorage()
        let manager = InlineCodeLayoutManager()
        storage.addLayoutManager(manager)
        storage.setAttributedString(try attributed("ab `cd` ef"))
        // "ab cd ef": the code is "cd" at 3..<5.
        #expect(manager.allowsHyphen(beforeCharacterAt: 1))
        #expect(manager.allowsHyphen(beforeCharacterAt: 3) == false, "the break before the code's first character")
        #expect(manager.allowsHyphen(beforeCharacterAt: 4) == false)
        #expect(manager.allowsHyphen(beforeCharacterAt: 5) == false, "the break after the code's last character")
        #expect(manager.allowsHyphen(beforeCharacterAt: 7))
        #expect(manager.allowsHyphen(beforeCharacterAt: storage.length))
        let plain = NSTextStorage()
        let plainManager = InlineCodeLayoutManager()
        plain.addLayoutManager(plainManager)
        plain.setAttributedString(NSAttributedString(string: "plain text"))
        #expect(plainManager.allowsHyphen(beforeCharacterAt: 3))
    }

    private func image(of view: UIView) -> Data? {
        UIGraphicsImageRenderer(bounds: view.bounds).pngData { _ in view.draw(view.bounds) }
    }
}
