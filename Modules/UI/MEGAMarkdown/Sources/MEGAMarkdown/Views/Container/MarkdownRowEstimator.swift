import MEGADesignToken
import UIKit

/// Guesses the height of a row from plain facts (text length, line count), without building text.
/// It uses the fonts and spacing of the resolved theme, so fewer rows move when their cells size themselves.
/// Arithmetic only, so it can run on any thread.
package struct MarkdownRowEstimator: Sendable {
    package let width: CGFloat
    package let bodyLine: CGFloat
    /// An average character is about half the body point size wide.
    package let bodyCharWidth: CGFloat
    /// Headings are about 1.3 body lines high.
    package let headingLine: CGFloat
    package let codeLine: CGFloat
    package let captionLine: CGFloat
    package let blockSpacing: CGFloat
    package let nestedSpacing: CGFloat
    package let headingTopSpacing: CGFloat

    package init(width: CGFloat, traits: UITraitCollection, theme: MarkdownTheme) {
        let resolved = theme.resolved(for: traits)
        self.width = width
        bodyLine = resolved.bodyFont.lineHeight
        bodyCharWidth = resolved.bodyFont.pointSize * 0.5
        headingLine = bodyLine * 1.3
        codeLine = resolved.codeFont.lineHeight
        captionLine = resolved.languageFont.lineHeight
        blockSpacing = resolved.blockSpacing
        nestedSpacing = resolved.nestedBlockSpacing
        headingTopSpacing = resolved.headingTopSpacing
    }

    // MARK: - Parts

    /// Wrapped text of `units` characters, `depth` decoration columns in. A heading outside lists and quotes
    /// adds the heading top spacing. No gap below.
    package func textHeight(units: Int, headingLevel: Int?, depth: Int) -> CGFloat {
        let wrapped = wrappedHeight(units: units, depth: depth, line: headingLevel == nil ? bodyLine : headingLine)
        return wrapped + (headingLevel != nil && depth == 0 ? headingTopSpacing : 0)
    }

    /// Lines of a code block or a part of one. Only the first part has the language label,
    /// and only the first and last parts have the outer padding.
    package func codeHeight(lines: Int, hasLanguage: Bool, isFirst: Bool, isLast: Bool) -> CGFloat {
        let padding = TokenSpacing._4
        let label = hasLanguage ? captionLine + TokenSpacing._2 : 0
        return CGFloat(lines) * codeLine + label + (isFirst ? padding : 0) + (isLast ? padding : 0)
    }

    /// A thematic break with its space above and below.
    package func dividerHeight() -> CGFloat {
        MarkdownBlockView.dividerHeight + 2 * TokenSpacing._3
    }

    /// The space below a row, the same as `MarkdownRowChrome.gapSpacing` adds.
    package func gapHeight(_ gap: MarkdownRowGap) -> CGFloat {
        let spacing = MarkdownRowChrome(gapBelow: gap).gapSpacing(blockSpacing: blockSpacing, nestedSpacing: nestedSpacing)
        return spacing.outer + spacing.inner
    }

    // MARK: - Preview rows

    /// The estimate of one preview row, gap below included. Never under 1 pt.
    package func height(of row: PreviewRow) -> CGFloat {
        let depth = row.chrome.decorations.count
        var height: CGFloat
        switch row.content {
        case .block(let block):
            height = blockHeight(block, depth: depth)
        case .textPiece(let text, let level, let isFirst):
            height = isFirst
                ? textHeight(units: text.text.utf8.count, headingLevel: level, depth: depth)
                : wrappedHeight(units: text.text.utf8.count, depth: depth, line: level == nil ? bodyLine : headingLine)
        case .codePiece(let language, let code, let isFirst, let isLast):
            height = codeHeight(lines: Self.lineCount(code), hasLanguage: language != nil, isFirst: isFirst, isLast: isLast)
        case .plainText(let code, let isFirst, let isLast):
            height = codeHeight(lines: Self.lineCount(code), hasLanguage: false, isFirst: isFirst, isLast: isLast)
        case .tablePage(_, let rows, let isFirst, _):
            height = tableHeight(rows: rows.count + (isFirst ? 1 : 0))
        case .notice:
            height = bodyLine * 2
        }
        return max(height + gapHeight(row.chrome.gapBelow), 1)
    }

    /// A whole block that was not split into pieces. Children of quotes and lists use the row's text width.
    private func blockHeight(_ block: ParsedBlock, depth: Int) -> CGFloat {
        switch block.kind {
        case .heading(_, let text):
            wrappedHeight(units: text.text.utf8.count, depth: depth, line: headingLine) + headingTopSpacing
        case .paragraph(let text):
            wrappedHeight(units: text.text.utf8.count, depth: depth, line: bodyLine)
        case .codeBlock(let language, let code):
            CGFloat(Self.lineCount(code)) * codeLine + 2 * TokenSpacing._4 + (language == nil ? 0 : captionLine)
        case .table(let table):
            tableHeight(rows: table.rows.count + 1)
        case .blockQuote(let children):
            children.reduce(0) { $0 + blockHeight($1, depth: depth) + nestedSpacing }
        case .list(let list):
            list.items.reduce(0) { total, item in
                item.blocks.reduce(total) { $0 + blockHeight($1, depth: depth) } + nestedSpacing
            }
        case .thematicBreak:
            dividerHeight()
        case .image:
            bodyLine
        }
    }

    private func tableHeight(rows: Int) -> CGFloat {
        CGFloat(rows) * (bodyLine + 2 * TokenSpacing._3)
    }

    private func wrappedHeight(units: Int, depth: Int, line: CGFloat) -> CGFloat {
        let columnWidth = TokenSpacing._2 + TokenSpacing._3 + bodyCharWidth
        let textWidth = max(width - 2 * TokenSpacing._5 - CGFloat(depth) * columnWidth, 60)
        let perLine = max(textWidth / bodyCharWidth, 1)
        return max((CGFloat(units) / perLine).rounded(.up), 1) * line
    }

    private static func lineCount(_ text: String) -> Int {
        text.utf8.reduce(1) { $0 + ($1 == 10 ? 1 : 0) }
    }
}
