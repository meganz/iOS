import MEGADesignToken
@testable import MEGAMarkdown
import Testing
import UIKit

/// Height estimates from plain facts and from preview rows, at a fixed width, text size and theme.
struct MarkdownRowEstimatorTests {
    private static let traits = UITraitCollection(preferredContentSizeCategory: .large)
    private static let estimator = MarkdownRowEstimator(width: 390, traits: traits, theme: .default)

    /// Characters per line at depth 0: the text width over half the body point size.
    private static var charactersPerLine: CGFloat {
        (390 - 2 * TokenSpacing._5) / estimator.bodyCharWidth
    }

    @Test func usesTheResolvedThemeFonts() {
        let resolved = MarkdownTheme.default.resolved(for: Self.traits)
        let estimator = Self.estimator
        #expect(estimator.bodyLine == resolved.bodyFont.lineHeight)
        #expect(estimator.bodyCharWidth == resolved.bodyFont.pointSize / 2)
        #expect(estimator.headingLine == resolved.bodyFont.lineHeight * 1.3)
        #expect(estimator.codeLine == resolved.codeFont.lineHeight)
        #expect(estimator.captionLine == resolved.languageFont.lineHeight)
        #expect(estimator.blockSpacing == MarkdownTheme.default.blockSpacing)
        #expect(estimator.nestedSpacing == MarkdownTheme.default.nestedBlockSpacing)
        #expect(estimator.headingTopSpacing == MarkdownTheme.default.headingTopSpacing)
    }

    @Test func textHeightWrapsAtTheTextWidth() {
        let estimator = Self.estimator
        let perLine = Self.charactersPerLine
        // One character, exactly one full line, and one character more.
        #expect(estimator.textHeight(units: 1, headingLevel: nil, depth: 0) == estimator.bodyLine)
        #expect(estimator.textHeight(units: 0, headingLevel: nil, depth: 0) == estimator.bodyLine)
        let full = Int(perLine.rounded(.down))
        #expect(estimator.textHeight(units: full, headingLevel: nil, depth: 0) == estimator.bodyLine)
        #expect(estimator.textHeight(units: full + 1, headingLevel: nil, depth: 0) == 2 * estimator.bodyLine)
        #expect(estimator.textHeight(units: 1_000, headingLevel: nil, depth: 0) == (1_000 / perLine).rounded(.up) * estimator.bodyLine)
    }

    /// Each decoration column takes its width from the text, so the same text wraps into more lines.
    @Test func textHeightNarrowsWithDepth() {
        let estimator = Self.estimator
        let column = TokenSpacing._2 + TokenSpacing._3 + estimator.bodyCharWidth
        let perLine = (390 - 2 * TokenSpacing._5 - 3 * column) / estimator.bodyCharWidth
        #expect(estimator.textHeight(units: 500, headingLevel: nil, depth: 3) == (500 / perLine).rounded(.up) * estimator.bodyLine)
        // A very deep row keeps a 60 pt text width.
        #expect(estimator.textHeight(units: 100, headingLevel: nil, depth: 40) == (100 / (60 / estimator.bodyCharWidth)).rounded(.up) * estimator.bodyLine)
    }

    /// A heading line is 1.3 body lines. The top spacing is added only outside lists and quotes.
    @Test func headingHeight() {
        let estimator = Self.estimator
        #expect(estimator.textHeight(units: 10, headingLevel: 2, depth: 0) == estimator.headingLine + estimator.headingTopSpacing)
        #expect(estimator.textHeight(units: 10, headingLevel: 2, depth: 1) == estimator.headingLine)
    }

    @Test func codeHeight() {
        let estimator = Self.estimator
        let line = estimator.codeLine
        let padding = TokenSpacing._4
        let label = estimator.captionLine + TokenSpacing._2
        #expect(estimator.codeHeight(lines: 3, hasLanguage: true, isFirst: true, isLast: true) == 3 * line + label + 2 * padding)
        #expect(estimator.codeHeight(lines: 3, hasLanguage: false, isFirst: true, isLast: false) == 3 * line + padding)
        #expect(estimator.codeHeight(lines: 1, hasLanguage: false, isFirst: false, isLast: true) == line + padding)
        #expect(estimator.codeHeight(lines: 7, hasLanguage: false, isFirst: false, isLast: false) == 7 * line)
    }

    @Test func dividerAndGapHeights() {
        let estimator = Self.estimator
        #expect(estimator.dividerHeight() == MarkdownBlockView.dividerHeight + 2 * TokenSpacing._3)
        #expect(estimator.gapHeight(.block) == estimator.blockSpacing)
        #expect(estimator.gapHeight(.nested) == estimator.nestedSpacing)
        #expect(estimator.gapHeight(.none) == 0)
        #expect(estimator.gapHeight(.betweenItems(taskItems: 0)) == 0)
        #expect(estimator.gapHeight(.betweenItems(taskItems: 1)) == ListBlockView.taskItemPadding)
        #expect(estimator.gapHeight(.betweenItems(taskItems: 2)) == 2 * ListBlockView.taskItemPadding)
    }

    // MARK: - Preview rows

    @Test func previewRowsUseTheParts() {
        let estimator = Self.estimator
        var text = InlineText()
        text.append(String(repeating: "a", count: 200), style: [])
        let first = PreviewRow(sourceLine: 0, content: .textPiece(text, headingLevel: 1, isFirst: true))
        let later = PreviewRow(sourceLine: 0, content: .textPiece(text, headingLevel: 1, isFirst: false))
        let lines = (200 / Self.charactersPerLine).rounded(.up)
        #expect(estimator.height(of: first) == lines * estimator.headingLine + estimator.headingTopSpacing)
        #expect(estimator.height(of: later) == lines * estimator.headingLine)

        let code = PreviewRow(sourceLine: 0, content: .codePiece(language: "swift", code: "a\nb\nc", isFirst: true, isLast: false, continuesLine: false))
        #expect(estimator.height(of: code) == estimator.codeHeight(lines: 3, hasLanguage: true, isFirst: true, isLast: false))
        let plain = PreviewRow(sourceLine: 0, content: .plainText("a\nb", isFirst: false, isLast: true, continuesLine: false))
        #expect(estimator.height(of: plain) == estimator.codeHeight(lines: 2, hasLanguage: false, isFirst: false, isLast: true))
        let notice = PreviewRow(sourceLine: 0, content: .notice(.shownAsPlainText))
        #expect(estimator.height(of: notice) == 2 * estimator.bodyLine)
    }

    /// The estimate adds the same gap below a row as the cells: `taskItemPadding` per task item between two items.
    @Test func previewRowAddsTheGapBelow() {
        let estimator = Self.estimator
        var text = InlineText()
        text.append("Item", style: [])
        var row = PreviewRow(sourceLine: 0, content: .textPiece(text, headingLevel: nil, isFirst: true))
        let noGap = estimator.height(of: row)
        #expect(noGap == estimator.bodyLine)
        let expected: [(MarkdownRowGap, CGFloat)] = [
            (.block, estimator.blockSpacing),
            (.nested, estimator.nestedSpacing),
            (.betweenItems(taskItems: 0), 0),
            (.betweenItems(taskItems: 1), 4),
            (.betweenItems(taskItems: 2), 8)
        ]
        for (gap, extra) in expected {
            row.chrome.gapBelow = gap
            #expect(estimator.height(of: row) == noGap + extra, "\(gap)")
        }
    }

    @Test func previewRowsOfEveryKindHaveAHeight() throws {
        let markdown = """
        # Heading

        Paragraph text.

        ```swift
        let a = 1
        let b = 2
        ```

        | A | B |
        |---|---|
        | 1 | 2 |

        ---

        ![alt](https://example.com/a.png)

        > - quoted item
        """
        var builder = PreviewRows.Builder(maxWeight: 0)
        for block in CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [] {
            builder.append(block, decorations: [], gap: .block)
        }
        builder.appendPlainText("raw line one\nraw line two", firstLine: 30)
        builder.appendNotice(.shownAsPlainText, line: 40)
        let rows = builder.rows
        let estimator = Self.estimator
        let gap = estimator.blockSpacing
        let table = try #require(rows.first { if case .tablePage = $0.content { true } else { false } })
        #expect(estimator.height(of: table) == 2 * (estimator.bodyLine + 2 * TokenSpacing._3) + gap)
        let divider = try #require(rows.first { if case .block(let block) = $0.content, case .thematicBreak = block.kind { true } else { false } })
        #expect(estimator.height(of: divider) == estimator.dividerHeight() + gap)
        let image = try #require(rows.first { if case .block(let block) = $0.content, case .image = block.kind { true } else { false } })
        #expect(estimator.height(of: image) == estimator.bodyLine + gap)
        for row in rows {
            #expect(estimator.height(of: row) >= 1)
        }
    }
}
