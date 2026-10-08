import MEGAMarkdown
import UIKit

/// Turns a rich row into the attributed text of its text view, with the fonts and colors of the resolved theme,
/// so a row looks like the same block in the preview.
struct RichTextStyler {
    /// The look of a whole row.
    enum Kind: Equatable {
        case body
        /// Level 1...6.
        case heading(Int)
        case quote
        case code
    }

    let resolved: MarkdownTheme.Resolved
    /// Text follows the layout direction, like SwiftUI `Text`. Code stays left to right, like in the preview.
    let isRightToLeft: Bool

    static func kind(of block: RichBlock) -> Kind? {
        switch block {
        case .paragraph, .listItem: .body
        case .heading(let level, _): .heading(level)
        case .quote: .quote
        case .codeBlock: .code
        case .thematicBreak, .rawSource: nil
        }
    }

    func baseFont(_ kind: Kind) -> UIFont {
        switch kind {
        case .body, .quote: resolved.bodyFont
        case .heading(let level): resolved.headingFont(level)
        case .code: resolved.codeFont
        }
    }

    private func baseColor(_ kind: Kind) -> UIColor {
        switch kind {
        case .body: resolved.bodyColor
        case .heading: resolved.headingColor
        case .quote: resolved.quoteTextColor
        case .code: resolved.codeForeground
        }
    }

    private func paragraphStyle(_ kind: Kind, direction: NSWritingDirection) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        if kind == .code {
            style.alignment = .left
            style.baseWritingDirection = .leftToRight
        } else {
            // A line of only inline code is lower than a plain line. This minimum stops the row from growing
            // when a plain letter follows. `usesFontLeading` is off, so a plain line is ascender plus descender.
            let font = baseFont(kind)
            style.minimumLineHeight = font.ascender - font.descender
            // A text view with natural direction follows the app language, not the text. So the row sets
            // the direction of its first letter, and natural alignment then follows it, like the preview.
            style.alignment = .natural
            // A row without a letter has no direction of its own. It follows the layout direction.
            style.baseWritingDirection = direction == .natural && isRightToLeft ? .rightToLeft : direction
        }
        return style
    }

    /// The attributes of text with `styles` in a row of `kind`. Links get a color and an underline only:
    /// a real `.link` attribute would make a tap open the link instead of placing the caret.
    func attributes(for styles: Set<RichSpanStyle>, kind: Kind, direction: NSWritingDirection = .natural) -> [NSAttributedString.Key: Any] {
        var font = baseFont(kind)
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: baseColor(kind),
            .paragraphStyle: paragraphStyle(kind, direction: direction)
        ]
        guard kind != .code else {
            attributes[.font] = font
            return attributes
        }
        if styles.contains(.code) {
            font = resolved.inlineCodeFont
            attributes[.baselineOffset] = resolved.inlineCodeBaselineOffset
            attributes[.foregroundColor] = resolved.inlineCodeColor
            attributes[.markdownInlineCode] = true
        }
        var traits: UIFontDescriptor.SymbolicTraits = []
        if styles.contains(.bold) { traits.insert(.traitBold) }
        if styles.contains(.italic) { traits.insert(.traitItalic) }
        if !traits.isEmpty, let descriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(traits)) {
            font = UIFont(descriptor: descriptor, size: font.pointSize)
        }
        if styles.contains(.underline) {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if styles.contains(.strikethrough) {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        if styles.contains(where: \.isLink) {
            attributes[.foregroundColor] = resolved.linkColor
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        attributes[.font] = font
        return attributes
    }

    /// The text of a text or code row with its styles. One sweep over the span edges.
    func attributedString(_ block: RichBlock) -> NSAttributedString {
        guard let kind = Self.kind(of: block) else { return NSAttributedString() }
        let direction = Self.writingDirection(of: block.richText?.text ?? "")
        guard let text = block.richText else {
            return NSAttributedString(string: block.codeText ?? "", attributes: attributes(for: [], kind: kind))
        }
        let result = NSMutableAttributedString(string: text.text, attributes: attributes(for: [], kind: kind, direction: direction))
        for (range, styles) in Self.pieces(of: text) where !styles.isEmpty {
            result.setAttributes(attributes(for: styles, kind: kind, direction: direction), range: NSRange(location: range.lowerBound, length: range.count))
        }
        return result
    }

    /// Right to left when the first letter is Hebrew, Arabic, Syriac or Thaana. Else natural, which follows the app.
    static func writingDirection(of text: String) -> NSWritingDirection {
        guard let first = text.unicodeScalars.first(where: { $0.properties.isAlphabetic }) else { return .natural }
        switch first.value {
        case 0x0590...0x08FF, 0xFB1D...0xFDFF, 0xFE70...0xFEFF: return .rightToLeft
        default: return .leftToRight
        }
    }

    /// The text split at every span edge, each piece with the styles that cover it. Spans are normalized: sorted, not empty.
    static func pieces(of text: RichText) -> [(range: Range<Int>, styles: Set<RichSpanStyle>)] {
        let length = text.length
        guard !text.spans.isEmpty else { return [(0..<length, [])] }
        // Start events before end events at one offset do not matter: a piece between them is empty.
        var events: [(offset: Int, isStart: Bool, style: RichSpanStyle)] = []
        events.reserveCapacity(text.spans.count * 2)
        for span in text.spans {
            events.append((min(span.range.lowerBound, length), true, span.style))
            events.append((min(span.range.upperBound, length), false, span.style))
        }
        events.sort { $0.offset < $1.offset }
        var pieces: [(range: Range<Int>, styles: Set<RichSpanStyle>)] = []
        var active: [RichSpanStyle: Int] = [:]
        var start = 0
        for event in events {
            if event.offset > start {
                pieces.append((start..<event.offset, Set(active.keys)))
                start = event.offset
            }
            if event.isStart {
                active[event.style, default: 0] += 1
            } else if let count = active[event.style] {
                active[event.style] = count > 1 ? count - 1 : nil
            }
        }
        if start < length { pieces.append((start..<length, Set(active.keys))) }
        return pieces
    }
}
