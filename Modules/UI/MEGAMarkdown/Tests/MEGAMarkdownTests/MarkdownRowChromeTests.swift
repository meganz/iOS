import Foundation
@testable import MEGAMarkdown
import Testing

/// Quote bar ends and gaps of `MarkdownRowChrome`, alone and as the preview rows build them.
@Suite struct MarkdownRowChromeTests {
    private func splitRows(_ markdown: String) -> [PreviewRow] {
        PreviewRows.rows(for: CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [], maxWeight: 0)
    }

    @Test func quoteBarEndsReadOneBitPerLevel() {
        let chrome = MarkdownRowChrome(decorations: Array(repeating: .quote, count: 3), quoteTops: 0b001, quoteBottoms: 0b110)
        #expect(chrome.quoteBarEnds(level: 0) == (top: true, bottom: false))
        #expect(chrome.quoteBarEnds(level: 1) == (top: false, bottom: true))
        #expect(chrome.quoteBarEnds(level: 2) == (top: false, bottom: true))
        #expect(chrome.quoteBarEnds(level: -1) == (top: false, bottom: false))
    }

    /// Levels past the visible ones have no bit. Their bars are hidden behind "…" and never round.
    @Test func quoteDeeperThanTheVisibleLevelsDoesNotRoundItsEnds() throws {
        let rows = splitRows(String(repeating: "> ", count: 10) + "deep")
        try #require(rows.count == 1)
        let chrome = rows[0].chrome
        #expect(chrome.decorations == Array(repeating: .quote, count: 10))
        for level in 0..<MarkdownRowChrome.maxVisibleNesting {
            #expect(chrome.quoteBarEnds(level: level) == (top: true, bottom: true), "level \(level)")
        }
        #expect(chrome.quoteBarEnds(level: 8) == (top: false, bottom: false))
        #expect(chrome.quoteBarEnds(level: 9) == (top: false, bottom: false))
        #expect(chrome.quoteTops == 0xFF)
        #expect(chrome.quoteBottoms == 0xFF)
    }

    /// The gap column counts only visible levels. A gap below a hidden level sits below the content.
    @Test func gapBelowAHiddenLevelSitsBelowTheContent() {
        let chrome = MarkdownRowChrome(decorations: Array(repeating: .quote, count: 10), gapBelow: .nested, gapOutsideColumns: 1)
        #expect(chrome.gapColumn == nil)
        let visible = MarkdownRowChrome(decorations: Array(repeating: .quote, count: 3), gapBelow: .nested, gapOutsideColumns: 1)
        #expect(visible.gapColumn == 2)
    }

    @Test func gapSpacingSplitsOuterAndInnerSpace() {
        let expected: [(MarkdownRowGap, outer: CGFloat, inner: CGFloat)] = [
            (.block, 20, 0), (.nested, 0, 4), (.betweenItems(taskItems: 2), 0, 8), (.none, 0, 0)
        ]
        for (gap, outer, inner) in expected {
            let spacing = MarkdownRowChrome(gapBelow: gap).gapSpacing(blockSpacing: 20, nestedSpacing: 4)
            #expect(spacing.outer == outer && spacing.inner == inner, "\(gap)")
        }
    }

    /// The largest start number cmark reads has 9 digits. The marker keeps the number of the whole list.
    @Test func orderedMarkerKeepsTheLargestNumber() throws {
        let rows = splitRows("999999998. a\n999999999. b")
        try #require(rows.count == 2)
        #expect(rows[1].chrome.decorations == [.listItem(.number(999_999_999), showsMarker: true)])
    }
}
