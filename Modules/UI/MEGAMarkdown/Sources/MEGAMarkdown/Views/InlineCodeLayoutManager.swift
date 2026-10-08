import MEGADesignToken
import UIKit

extension NSAttributedString.Key {
    /// Marks inline code. `InlineCodeLayoutManager` draws the chip behind it.
    package static let markdownInlineCode = NSAttributedString.Key("MEGAMarkdown.inlineCode")
}

/// Draws the Figma inline code chip: surface 1 fill, 1px strong border, radius 4, one box per line.
/// A subclass, because UIKit has no attribute for a bordered, rounded background that splits per line.
/// It also owns the line rule of text with inline code, so the rich editor row and the preview lay it out the same.
/// `package`, so other targets of this package draw the same chip.
package final class InlineCodeLayoutManager: NSLayoutManager {
    /// No border width token exists.
    package static let borderWidth: CGFloat = 1
    /// Figma: from the code text to the outer edge of the chip, `TokenSpacing._1` plus the border.
    package static let chipPadding = TokenSpacing._1 + borderWidth

    package var fillColor = TokenColors.Background.surface1
    package var borderColor = TokenColors.Border.strong
    /// The chip is this tall, centered on its line. Nil: as tall as the line.
    package var chipHeight: CGFloat?
    /// The space below every line of a row with inline code. The chip leaves it free.
    package var lineGap: CGFloat = 0
    /// The font of the plain text. A line of only inline code keeps the baseline of this font.
    package var baseFont: UIFont?
    /// True while the text holds inline code. Every line is then as tall as the chip.
    package private(set) var hasInlineCode = false

    /// The first or last inline code changes the height of every line, so the whole text is laid out again.
    override package func processEditing(
        for textStorage: NSTextStorage,
        edited editMask: NSTextStorage.EditActions,
        range newCharRange: NSRange,
        changeInLength delta: Int,
        invalidatedRange invalidatedCharRange: NSRange
    ) {
        var found = false
        textStorage.enumerateAttribute(.markdownInlineCode, in: NSRange(location: 0, length: textStorage.length)) { value, _, stop in
            if value != nil {
                found = true
                stop.pointee = true
            }
        }
        let invalidated = found == hasInlineCode ? invalidatedCharRange : NSRange(location: 0, length: textStorage.length)
        hasInlineCode = found
        super.processEditing(for: textStorage, edited: editMask, range: newCharRange, changeInLength: delta, invalidatedRange: invalidated)
    }

    /// The line rule. The owner of the layout manager calls it from
    /// `layoutManager(_:shouldSetLineFragmentRect:lineFragmentUsedRect:baselineOffset:in:forGlyphRange:)`.
    /// - TextKit 1 puts the extra height of `minimumLineHeight` above the text. So a line of only inline code
    ///   sits lower than plain text. Its baseline moves up to where plain text puts it.
    /// - Figma: with inline code, every line is as tall as the chip, with the text centered and `lineGap` below.
    package func setLineFragmentRect(
        _ lineFragmentRect: UnsafeMutablePointer<CGRect>,
        usedRect: UnsafeMutablePointer<CGRect>,
        baselineOffset: UnsafeMutablePointer<CGFloat>
    ) -> Bool {
        guard let baseFont else { return false }
        let natural = lineFragmentRect.pointee.height
        var baseline = min(baselineOffset.pointee, natural + baseFont.descender)
        var height = natural
        if hasInlineCode, let chipHeight {
            let lineHeight = max(natural, chipHeight)
            baseline += (lineHeight - natural) / 2
            height = lineHeight + lineGap
        }
        guard baseline != baselineOffset.pointee || height != natural else { return false }
        baselineOffset.pointee = baseline
        lineFragmentRect.pointee.size.height = height
        usedRect.pointee.size.height = height
        return true
    }

    /// The height of laid out text that is `usedHeight` tall. The last line has no gap below it.
    package func textHeight(usedHeight: CGFloat) -> CGFloat {
        hasInlineCode ? usedHeight - lineGap : usedHeight
    }

    override package func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        // Super draws the selection and other backgrounds first.
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage else { return }
        let characters = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(.markdownInlineCode, in: characters) { value, range, _ in
            guard value != nil else { return }
            for rect in chipRects(forCharacterRange: range) {
                // Inset by half the line, so the 1px border stays inside the box.
                let path = UIBezierPath(roundedRect: rect.offsetBy(dx: origin.x, dy: origin.y).insetBy(dx: 0.5, dy: 0.5), cornerRadius: TokenRadius.small)
                path.lineWidth = Self.borderWidth
                fillColor.setFill()
                path.fill()
                borderColor.setStroke()
                path.stroke()
            }
        }
    }

    /// One box per line the range covers, by the preview's box rule `InlineCodeChipBoxes`.
    /// At the start or end of a line the box reaches past the text edge, so the text view keeps room for it.
    package func chipRects(forCharacterRange range: NSRange) -> [CGRect] {
        let glyphs = glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        guard glyphs.length > 0 else { return [] }
        var rects: [CGRect] = []
        let text = (textStorage?.string ?? "") as NSString
        enumerateLineFragments(forGlyphRange: glyphs) { lineRect, _, container, lineGlyphs, _ in
            let lineHeight = lineRect.height - self.lineGap
            let line = (lineGlyphs.location..<NSMaxRange(lineGlyphs)).map { index in
                let bounds = self.boundingRect(forGlyphRange: NSRange(location: index, length: 1), in: container)
                let isChip = NSLocationInRange(index, glyphs)
                return ChipLineGlyph(
                    rect: CGRect(x: bounds.minX, y: lineRect.minY, width: bounds.width, height: lineHeight),
                    isChip: isChip,
                    isBlank: isChip && self.isWhitespace(glyphAt: index, in: text)
                )
            }
            rects += InlineCodeChipBoxes.boxes(line, height: self.chipHeight)
        }
        return rects
    }

    private func isWhitespace(glyphAt glyphIndex: Int, in text: NSString) -> Bool {
        let index = characterIndexForGlyph(at: glyphIndex)
        guard index < text.length else { return false }
        // Tabs and ideographic spaces can end a wrapped line too, not only U+0020.
        guard let scalar = Unicode.Scalar(text.character(at: index)) else { return false }
        return CharacterSet.whitespaces.contains(scalar)
    }
}
