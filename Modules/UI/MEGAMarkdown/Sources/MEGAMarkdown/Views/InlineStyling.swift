import MEGADesignToken
import SwiftUI

/// Max characters in one `Text`. Longer text is split into several `Text` views.
/// One huge `Text` blocks the main thread while it measures.
let maxTextMeasureCharacters = 50_000

extension MarkdownTheme {
    /// Adds theme styles for inline code and links on top of what `Text` already
    /// draws from the Foundation inline attributes (bold, italic, strikethrough, code).
    func styledInline(_ text: AttributedString, codeFont: Font) -> AttributedString {
        var result = text
        for run in text.runs {
            let intent = run.inlinePresentationIntent ?? []
            if intent.contains(.code) {
                result[run.range].font = codeFont
                // iOS 17 has no text renderer, so the run keeps its own fill. `inlineText` drops it on iOS 18 and later.
                result[run.range].backgroundColor = inlineCodeBackground
                result[run.range].foregroundColor = inlineCodeColor
            }
            // A tapped link goes to the SwiftUI `openURL` action. The host sets that action to choose which URLs open.
            if run.link != nil {
                result[run.range].foregroundColor = linkColor
                result[run.range].underlineStyle = .single
            }
        }
        return result
    }
}

/// Splits `text` into pieces of at most `maxLength` characters.
/// Each piece keeps its inline styles. Short text comes back as one piece.
func splitForMeasuring(_ text: AttributedString, maxLength: Int = maxTextMeasureCharacters) -> [AttributedString] {
    let characters = text.characters
    var pieces: [AttributedString] = []
    var start = characters.startIndex
    while start < characters.endIndex {
        let end = characters.index(start, offsetBy: maxLength, limitedBy: characters.endIndex) ?? characters.endIndex
        pieces.append(AttributedString(text[start..<end]))
        start = end
    }
    return pieces.isEmpty ? [text] : pieces
}

/// Shows inline Markdown text. Splits very long text into several stacked `Text` views.
struct InlineTextView: View {
    let text: AttributedString
    let font: Font
    let color: Color

    @Environment(\.markdownTheme) private var theme
    @ScaledMetric(relativeTo: .body) private var codeScale: CGFloat = 1

    var body: some View {
        let shown = Self.withoutHTMLBlockLineEnd(text)
        let pieces = splitForMeasuring(theme.styledInline(shown, codeFont: theme.inlineCodeFont(scale: codeScale)))
        VStack(alignment: .leading, spacing: 0) {
            // Most text is one piece. A plain child skips the `ForEach` item work on each layout.
            if pieces.count == 1 {
                inlineText(pieces[0])
            } else {
                ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                    inlineText(piece)
                }
            }
        }
        .font(font)
        .foregroundStyle(color)
        .tint(theme.linkColor)
        .inlineCodeChips(theme, for: shown)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The source of an HTML block ends with a line end. `Text` would draw it as an empty line below the block.
    static func withoutHTMLBlockLineEnd(_ text: AttributedString) -> AttributedString {
        guard let last = text.runs.last, last.inlinePresentationIntent?.contains(.blockHTML) == true else { return text }
        var result = text
        while result.characters.last?.isNewline == true {
            result.characters.removeLast()
        }
        return result
    }
}

// MARK: - Inline code chip

/// Marks the `Text` of an `inline code` run, so `InlineCodeChipRenderer` can find it.
/// `Text.Layout` gives no text, so the chip keeps its own, to find blanks at the end of a line.
struct InlineCodeChip: TextAttribute {
    /// Tells two chips with the same text apart.
    let id: Int
    let utf16: [UInt16]

    func isBlank(at offset: Int) -> Bool {
        guard utf16.indices.contains(offset), let scalar = Unicode.Scalar(utf16[offset]) else { return false }
        return CharacterSet.whitespaces.contains(scalar)
    }
}

/// One `Text` for styled inline text, for a view with `inlineCodeChips(_:for:)`. Each code run gets the `InlineCodeChip` attribute.
/// `Text.customAttribute` works only on a whole `Text`, so code runs become separate `Text` values.
func inlineText(_ text: AttributedString) -> Text {
    var pieces: [Text] = []
    var segment = AttributedString()
    var segmentIsCode = false
    var chipCount = 0

    func flush() {
        guard !segment.characters.isEmpty else { return }
        // The renderer draws the fill as a rounded box. The square run fill would show around it.
        if segmentIsCode, #available(iOS 18.0, *) {
            segment.backgroundColor = nil
        }
        var piece = Text(segment)
        if segmentIsCode {
            piece = piece.customAttribute(InlineCodeChip(id: chipCount, utf16: Array(String(segment.characters).utf16)))
            chipCount += 1
        }
        pieces.append(piece)
        segment = AttributedString()
    }

    for run in text.runs {
        let isCode = run.inlinePresentationIntent?.contains(.code) == true
        if isCode != segmentIsCode {
            flush()
            segmentIsCode = isCode
        }
        segment += AttributedString(text[run.range])
    }
    flush()
    return joined(pieces) ?? Text(text)
}

/// Joins pieces as a balanced tree. SwiftUI draws `a + b` by recursion, so a long left-deep chain
/// can overflow the main-thread stack. A balanced tree is only log2(n) deep.
private func joined(_ pieces: [Text]) -> Text? {
    var level = pieces
    while level.count > 1 {
        level = stride(from: 0, to: level.count, by: 2).map { index in
            index + 1 < level.count ? level[index] + level[index + 1] : level[index]
        }
    }
    return level.first
}

/// One glyph of a line, as the chip renderer sees it.
struct ChipLineGlyph: Equatable {
    var rect: CGRect
    /// True for a glyph of `inline code`.
    var isChip: Bool
    /// True for a blank inside a chip. Blanks outside chips are not known: `Text.Layout` gives no text.
    var isBlank = false
}

/// The chip box rule. It works on plain glyph boxes, so tests can check it without drawing.
enum InlineCodeChipBoxes {
    /// The chip boxes of one line of glyphs, in order.
    /// - Figma ends a box at the last letter, so blanks at the end of a box are left out.
    /// - A box grows by `TokenSpacing._1` on each side, but it stays `margin` inside the glyph next to it,
    ///   like Android (`MarkdownInlineCodeChips.kt`). So a word space stays visible next to a chip.
    /// - Two chips with only a space between them meet halfway, `margin` apart.
    /// - A box stays inside the text's left edge (x = 0).
    static func boxes(_ glyphs: [ChipLineGlyph]) -> [CGRect] {
        var boxes: [(rect: CGRect, glyphs: ClosedRange<Int>)] = []
        var index = 0
        while index < glyphs.count {
            guard glyphs[index].isChip else {
                index += 1
                continue
            }
            let first = index
            while index < glyphs.count, glyphs[index].isChip {
                index += 1
            }
            var last = index - 1
            while last > first, glyphs[last].isBlank {
                last -= 1
            }
            let ink = glyphs[first...last].dropFirst().reduce(glyphs[first].rect) { $0.union($1.rect) }
            // Neighbours by position, not by text order, so right-to-left lines work too.
            let others = glyphs.indices.filter { $0 < first || $0 > last }.map { glyphs[$0].rect }
            var minX = ink.minX - TokenSpacing._1
            var maxX = ink.maxX + TokenSpacing._1
            if let leftNeighbour = others.filter({ $0.maxX <= ink.minX + 0.5 }).max(by: { $0.maxX < $1.maxX }) {
                minX = max(minX, min(leftNeighbour.minX + margin, ink.minX))
            }
            if let rightNeighbour = others.filter({ $0.minX >= ink.maxX - 0.5 }).min(by: { $0.minX < $1.minX }) {
                maxX = min(maxX, max(rightNeighbour.maxX - margin, ink.maxX))
            }
            minX = max(minX, 0)
            boxes.append((CGRect(x: minX, y: ink.minY, width: max(maxX - minX, 0), height: ink.height), first...last))
        }
        boxes.sort { $0.rect.minX < $1.rect.minX }
        for pairIndex in boxes.indices.dropFirst() {
            let left = boxes[pairIndex - 1]
            let right = boxes[pairIndex]
            guard right.rect.minX - left.rect.maxX < margin else { continue }
            let leftInkMaxX = glyphs[left.glyphs].map(\.rect.maxX).max() ?? left.rect.maxX
            let rightInkMinX = glyphs[right.glyphs].map(\.rect.minX).min() ?? right.rect.minX
            let middle = (leftInkMaxX + rightInkMinX) / 2
            let leftMaxX = max(leftInkMaxX, middle - margin / 2)
            let rightMinX = min(rightInkMinX, middle + margin / 2)
            boxes[pairIndex - 1].rect.size.width = leftMaxX - left.rect.minX
            boxes[pairIndex].rect.size.width = right.rect.maxX - rightMinX
            boxes[pairIndex].rect.origin.x = rightMinX
        }
        return boxes.map(\.rect)
    }

    /// The least space between a chip box and the glyph or chip next to it.
    static let margin: CGFloat = 2
}

/// Draws the Figma chip behind `inline code`: fill, border and rounded corners, one box per line.
/// SwiftUI skips a text renderer when text selection is on, so views that use it keep selection off.
@available(iOS 18.0, *)
struct InlineCodeChipRenderer: TextRenderer {
    let fill: Color
    let border: Color

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let starts = Self.chipStarts(in: layout)
        let chips = layout.flatMap { Self.chipRects(in: $0, starts: starts) }
        for rect in chips {
            context.fill(Path(roundedRect: rect, cornerRadius: TokenRadius.small), with: .color(fill))
        }
        for line in layout {
            context.draw(line)
        }
        // After the text, so nothing covers the border.
        let inset = Self.borderWidth / 2
        for rect in chips {
            let path = Path(roundedRect: rect.insetBy(dx: inset, dy: inset), cornerRadius: TokenRadius.small)
            context.stroke(path, with: .color(border), lineWidth: Self.borderWidth)
        }
    }

    /// The first character of each chip, so a glyph's character index becomes an offset into the chip text.
    static func chipStarts(in layout: Text.Layout) -> [Int: Text.Layout.CharacterIndex] {
        var starts: [Int: Text.Layout.CharacterIndex] = [:]
        for line in layout {
            for run in line {
                guard let chip = run[InlineCodeChip.self], let first = run.characterIndices.min() else { continue }
                starts[chip.id] = min(starts[chip.id] ?? first, first)
            }
        }
        return starts
    }

    /// One box per group of side-by-side code runs in a line, so bold code inside a chip is still one chip.
    static func chipRects(in line: Text.Layout.Line, starts: [Int: Text.Layout.CharacterIndex]) -> [CGRect] {
        var glyphs: [ChipLineGlyph] = []
        for run in line {
            let chip = run[InlineCodeChip.self]
            let start = chip.flatMap { starts[$0.id] }
            for slice in run {
                var isBlank = false
                if let chip, let start, let first = slice.characterIndices.first {
                    isBlank = chip.isBlank(at: start.distance(to: first))
                }
                glyphs.append(ChipLineGlyph(rect: slice.typographicBounds.rect, isChip: chip != nil, isBlank: isBlank))
            }
        }
        return InlineCodeChipBoxes.boxes(glyphs)
    }

    // No design token for border width.
    static let borderWidth: CGFloat = 1
}

extension View {
    /// Draws the border around `inline code`. iOS 17 has no `textRenderer`, so code keeps only its fill there.
    /// Text without inline code keeps the normal SwiftUI drawing. Only text that needs a chip goes through the renderer.
    @ViewBuilder
    func inlineCodeChips(_ theme: MarkdownTheme, for text: AttributedString) -> some View {
        if #available(iOS 18.0, *), text.runs.contains(where: { $0.inlinePresentationIntent?.contains(.code) == true }) {
            textRenderer(InlineCodeChipRenderer(fill: theme.inlineCodeBackground, border: theme.inlineCodeBorderColor))
        } else {
            self
        }
    }
}
