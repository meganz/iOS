import Foundation
@testable import MEGAMarkdown
import Testing

@Suite struct PreviewRowsTests {
    private func rows(_ markdown: String) -> [PreviewRow] {
        PreviewRows.rows(for: CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [])
    }

    /// Every block split into rows, so each row is one leaf block or piece.
    private func splitRows(_ markdown: String) -> [PreviewRow] {
        PreviewRows.rows(for: CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [], maxWeight: 0)
    }

    private func isBlock(_ row: PreviewRow) -> Bool {
        if case .block = row.content { return true }
        return false
    }

    @Test func normalDocumentIsOneRowPerBlock() throws {
        let markdown = try ParserGoldenTests.fixture("c-mixed-100k.md")
        let result = rows(markdown)
        let blocks = MarkdownParser.parse(markdown).blocks
        #expect(result.count == blocks.count)
        #expect(result.map(\.sourceLine) == blocks.map(\.sourceLine))
        #expect(result.allSatisfy { isBlock($0) && $0.chrome.decorations.isEmpty })
        #expect(result.dropLast().allSatisfy { $0.chrome.gapBelow == .block })
        #expect(result.last?.chrome.gapBelow == MarkdownRowGap.none)
    }

    @Test func rowLinesNeverGoDown() throws {
        let markdown = try ParserGoldenTests.fixture("c-mixed-100k.md")
            + (1...300).map { "\($0). item\n" }.joined()
            + "\n```\n" + (1...500).map { "line \($0)" }.joined(separator: "\n") + "\n```\n"
        let lines = rows(markdown).map(\.sourceLine)
        #expect(zip(lines, lines.dropFirst()).allSatisfy { $0 <= $1 })
    }

    @Test func shortListStaysOneRow() throws {
        let result = rows((1...60).map { "- item \($0)" }.joined(separator: "\n"))
        try #require(result.count == 1)
        #expect(isBlock(result[0]))
    }

    @Test func longListIsOneRowPerItemWithGlobalNumbers() throws {
        let result = rows((0..<1_000).map { "\($0 + 5). item" }.joined(separator: "\n"))
        try #require(result.count == 1_000)
        for (index, row) in result.enumerated() {
            #expect(row.chrome.decorations == [.listItem(.number(5 + index), showsMarker: true)])
            #expect(row.sourceLine == index)
        }
        #expect(result[0].chrome.gapBelow == .betweenItems(taskItems: 0))
    }

    @Test func itemMarkerShowsOnlyOnItsFirstRow() throws {
        let item = "- first paragraph\n\n  second paragraph\n"
        let result = rows(String(repeating: item, count: 200))
        try #require(result.count == 400)
        for (index, row) in result.enumerated() {
            #expect(row.chrome.decorations == [.listItem(.bullet, showsMarker: index.isMultiple(of: 2))], "row \(index)")
        }
    }

    @Test func taskItemsKeepTheirState() throws {
        // Checked and unchecked items alternate, so a wrong or shifted state shows.
        let result = rows((0..<200).map { "- [\($0.isMultiple(of: 2) ? "x" : " ")] task \($0)" }.joined(separator: "\n"))
        try #require(result.count == 200)
        for (index, row) in result.enumerated() {
            #expect(row.chrome.decorations == [.listItem(.checkbox(isChecked: index.isMultiple(of: 2)), showsMarker: true)])
        }
    }

    @Test func bigTableIsSplitIntoPages() throws {
        let markdown = "| a | b |\n|---|---|\n" + (0..<1_000).map { "| \($0) | x |" }.joined(separator: "\n")
        let result = rows(markdown)
        var covered: [Int] = []
        for (index, row) in result.enumerated() {
            guard case .tablePage(let table, let range, let isFirst, let isLast) = row.content else {
                Issue.record("row \(index) is not a table page")
                return
            }
            #expect(table.header.map(\.text) == ["a", "b"])
            #expect(isFirst == (index == 0))
            #expect(isLast == (index == result.count - 1))
            #expect(row.sourceLine == (index == 0 ? 0 : 2 + range.lowerBound))
            covered += Array(range)
        }
        #expect(covered == Array(0..<1_000))
        #expect(result.count == 1_000 / PreviewRows.tableRowsPerPage)
    }

    /// The parser drops empty rows. Kept row `i` is on line 3 + 2i, so each page starts on its first row's own line.
    @Test func tablePageAfterDroppedRowsKeepsItsSourceLine() throws {
        let markdown = "| a | b |\n|---|---|\n" + (0..<1_000).map { "| | |\n| \($0) | x |" }.joined(separator: "\n")
        let result = rows(markdown)
        let pageSize = PreviewRows.tableRowsPerPage
        try #require(result.count == 1_000 / pageSize)
        // Page 2 starts at kept row 50, on line 103. Counting rows from the header would give 52.
        #expect(result.map(\.sourceLine) == result.indices.map { $0 == 0 ? 0 : 3 + 2 * pageSize * $0 })
    }

    @Test func wideTablePagesKeepFewCells() throws {
        let header = "|" + String(repeating: " h |", count: 5_000) + "\n"
        let delimiter = "|" + String(repeating: "---|", count: 5_000) + "\n"
        let row = "|" + String(repeating: " c |", count: 5_000) + "\n"
        let result = rows(header + delimiter + String(repeating: row, count: 200))
        guard case .tablePage(_, let range, _, _) = result.first?.content else {
            Issue.record("no table page")
            return
        }
        let pageRows = PreviewRows.tableCellsPerPage / TableLimits.maxColumns
        #expect(range.count == pageRows)
        // Every page stays small, and together the pages hold every row once.
        var covered: [Int] = []
        for row in result {
            guard case .tablePage(_, let range, _, _) = row.content else {
                Issue.record("not a table page")
                return
            }
            #expect(range.count <= pageRows)
            covered += Array(range)
        }
        #expect(covered == Array(0..<200))
    }

    @Test func bigCodeBlockIsSplitIntoPieces() throws {
        let lines = (1...1_000).map { "line \($0)" }
        let result = rows("```swift\n" + lines.joined(separator: "\n") + "\n```")
        var joined: [String] = []
        for (index, row) in result.enumerated() {
            guard case .codePiece(let language, let code, let isFirst, let isLast, let continuesLine) = row.content else {
                Issue.record("row \(index) is not a code piece")
                return
            }
            #expect(language == (index == 0 ? "swift" : nil))
            #expect(isFirst == (index == 0))
            #expect(isLast == (index == result.count - 1))
            #expect(!continuesLine)
            joined.append(code)
        }
        #expect(joined.joined(separator: "\n") == lines.joined(separator: "\n"))
        try #require(result.count == 10)
        #expect(result[1].sourceLine == 101)
    }

    @Test func longCodeLineIsCutAndMarked() {
        let longLine = String(repeating: "a", count: 20_000)
        let result = rows("```\n" + longLine + "\n```")
        let codes = result.compactMap { row -> String? in
            if case .codePiece(_, let code, _, _, _) = row.content { return code }
            return nil
        }
        let continues = result.compactMap { row -> Bool? in
            if case .codePiece(_, _, _, _, let continuesLine) = row.content { return continuesLine }
            return nil
        }
        #expect(codes.count == 3)
        #expect(continues == [false, true, true])
        #expect(codes.dropFirst().allSatisfy { $0.hasPrefix(PreviewRows.codeContinuationMarker) })
        #expect(codes.map { $0.replacingOccurrences(of: PreviewRows.codeContinuationMarker, with: "") }.joined() == longLine)
    }

    @Test func longParagraphIsSplitIntoPieces() {
        let words = (0..<100_000).map { $0.isMultiple(of: 7) ? "**b\($0)**" : "w\($0)" }.joined(separator: " ") + " 👩‍💻"
        let result = rows(words)
        var text = ""
        for row in result {
            guard case .textPiece(let piece, let level, _) = row.content else {
                Issue.record("not a text piece")
                return
            }
            #expect(level == nil)
            #expect(piece.text.utf8.count <= PreviewRows.textPieceBytes)
            text += piece.text
        }
        #expect(result.count > 100)
        #expect(text == MarkdownParser.parse(words).blocks.first?.paragraphText)
    }

    @Test func longHeadingPiecesKeepTheLevel() {
        let result = rows("## " + String(repeating: "word ", count: 30_000))
        #expect(result.count > 1)
        var text = ""
        for row in result {
            guard case .textPiece(let piece, let level, _) = row.content else {
                Issue.record("not a text piece")
                return
            }
            #expect(level == 2)
            text += piece.text
        }
        // No text is lost or repeated between the pieces.
        #expect(text == Array(repeating: "word", count: 30_000).joined(separator: " "))
    }

    @Test func textPieceRangesCoverTheTextOnCharacterBoundaries() {
        let text = String(repeating: "é👩‍💻x", count: 3_000)
        let ranges = PreviewRows.Builder.textPieceRanges(text)
        // The text is longer than one piece, so the boundary checks below really run on cuts.
        #expect(ranges.count > 1)
        #expect(ranges.first?.lowerBound == 0)
        #expect(ranges.last?.upperBound == text.utf8.count)
        #expect(zip(ranges, ranges.dropFirst()).allSatisfy { $0.upperBound == $1.lowerBound })
        let utf8 = Array(text.utf8)
        for range in ranges {
            #expect(String(bytes: utf8[range], encoding: .utf8) != nil)
        }
    }

    /// A newline in the back-off window wins over a later space, so the piece ends with a whole line.
    @Test func textPieceCutPrefersANewline() {
        let line = Array(repeating: "word", count: 12).joined(separator: " ")
        let text = Array(repeating: line, count: 400).joined(separator: "\n")
        let ranges = PreviewRows.Builder.textPieceRanges(text)
        let utf8 = Array(text.utf8)
        #expect(ranges.count > 1)
        for range in ranges.dropLast() {
            #expect(utf8[range.upperBound - 1] == UInt8(ascii: "\n"), "cut at \(range.upperBound)")
        }
    }

    /// With no newline near the cut, the cut stays after a space.
    @Test func textPieceCutFallsBackToASpace() {
        let text = Array(repeating: "word", count: 3_000).joined(separator: " ")
        let ranges = PreviewRows.Builder.textPieceRanges(text)
        let utf8 = Array(text.utf8)
        #expect(ranges.count > 1)
        for range in ranges.dropLast() {
            #expect(utf8[range.upperBound - 1] == UInt8(ascii: " "), "cut at \(range.upperBound)")
        }
    }

    @Test func nestedBigQuoteKeepsItsDecorations() {
        let inner = (0..<300).map { "text \($0)" }.joined(separator: "\n\n")
        let quoted = inner.split(separator: "\n", omittingEmptySubsequences: false).map { String(repeating: "> ", count: 12) + $0 }
        let result = rows(quoted.joined(separator: "\n"))
        #expect(result.count == 300)
        #expect(result.allSatisfy { $0.chrome.decorations == Array(repeating: .quote, count: 12) })
    }

    @Test func deeplyNestedSmallBlockIsSplitToKeepWidth() throws {
        // Nesting deeper than the visible limit must not render as one nested block.
        let result = rows(String(repeating: "> ", count: 12) + "deep")
        try #require(result.count == 1)
        #expect(result[0].chrome.decorations.count == 12)
    }

    /// The whole quote block has one bar with round ends at its top and bottom only.
    /// Each quote has its own ends: two quotes in a row are not joined, and a nested quote has its own bar.
    @Test func quoteBarEndsFollowTheQuoteNotTheRow() throws {
        let single = splitRows("> One line.")
        try #require(single.count == 1)
        #expect(single[0].chrome.quoteBarEnds(level: 0) == (top: true, bottom: true), "one-row quote")

        // A blank line without ">" ends a quote, so these are two quotes.
        let twoQuotes = splitRows("> First quote.\n\n> Second quote.")
        try #require(twoQuotes.count == 2)
        for (index, row) in twoQuotes.enumerated() {
            #expect(row.chrome.quoteBarEnds(level: 0) == (top: true, bottom: true), "quote \(index) joined to the other quote")
        }

        let nested = splitRows("> Outer start.\n>\n> > Inner.\n>\n> Outer end.")
        try #require(nested.count == 3)
        try #require(nested[1].chrome.decorations == [.quote, .quote])
        #expect(nested[0].chrome.quoteBarEnds(level: 0) == (top: true, bottom: false), "outer first row")
        #expect(nested[1].chrome.quoteBarEnds(level: 0) == (top: false, bottom: false), "outer middle row")
        #expect(nested[1].chrome.quoteBarEnds(level: 1) == (top: true, bottom: true), "inner quote")
        #expect(nested[2].chrome.quoteBarEnds(level: 0) == (top: false, bottom: true), "outer last row")

        // A quote inside a list item: its bar is the second column.
        let inList = splitRows("- > Quoted in a list.\n  >\n  > Second paragraph.")
        try #require(inList.count == 2)
        #expect(inList[0].chrome.quoteBarEnds(level: 0) == (top: false, bottom: false), "the list column has no bar")
        #expect(inList[0].chrome.quoteBarEnds(level: 1) == (top: true, bottom: false), "quote in list, first row")
        #expect(inList[1].chrome.quoteBarEnds(level: 1) == (top: false, bottom: true), "quote in list, last row")
    }

    /// The gap between two items sits below the item's marker column. A gap inside one item or quote
    /// sits below the content, inside every column.
    @Test func gapColumnIsTheColumnTheGapSitsBelow() throws {
        let nestedList = splitRows("- one\n  - inner a\n  - inner b\n- two")
        try #require(nestedList.count == 4)
        #expect(nestedList.map(\.chrome.decorations.count) == [1, 2, 2, 1])
        #expect(nestedList[0].chrome.gapBelow == .nested)
        #expect(nestedList[0].chrome.gapColumn == nil, "list item text to its nested list")
        #expect(nestedList[1].chrome.gapBelow == .betweenItems(taskItems: 0))
        #expect(nestedList[1].chrome.gapColumn == 1, "between items of the inner list")
        #expect(nestedList[2].chrome.gapBelow == .betweenItems(taskItems: 0))
        #expect(nestedList[2].chrome.gapColumn == 0, "between items of the outer list")
        #expect(nestedList[3].chrome.gapColumn == nil, "last row")

        let quote = splitRows("> first\n>\n> second")
        try #require(quote.count == 2)
        #expect(quote[0].chrome.gapBelow == .nested)
        #expect(quote[0].chrome.gapColumn == nil)

        let topLevel = splitRows("Paragraph.\n\n- item")
        try #require(topLevel.count == 2)
        #expect(topLevel[0].chrome.gapBelow == .block)
        #expect(topLevel[0].chrome.gapColumn == nil)
    }

    /// Like `ListBlockView`: each task item adds `taskItemPadding` to the gap on its side.
    @Test func gapBetweenItemsCountsTheTaskItems() throws {
        let result = splitRows("- [ ] task\n- plain\n- [x] task\n- [ ] task\n- plain\n- plain")
        try #require(result.count == 6)
        #expect(result.map(\.chrome.gapBelow) == [
            .betweenItems(taskItems: 1), .betweenItems(taskItems: 1), .betweenItems(taskItems: 2),
            .betweenItems(taskItems: 1), .betweenItems(taskItems: 0), .none
        ])
        let spacing = result.map { $0.chrome.gapSpacing(blockSpacing: 20, nestedSpacing: 4) }
        #expect(spacing.map(\.outer) == [0, 0, 0, 0, 0, 0])
        #expect(spacing.map(\.inner) == [4, 4, 8, 4, 0, 0])
        #expect(ListBlockView.taskItemPadding == 4)
    }

    /// A list item with no blocks still shows its marker, and the numbers stay in order.
    /// The viewer parse drops such an item, so the blocks are built here.
    @Test func emptyListItemKeepsItsMarker() throws {
        var text = InlineText()
        text.append("a", style: [])
        let rowsOfList = { (isOrdered: Bool) in
            let items = [0, 2, 4].map { line in
                ParsedListItem(checkbox: nil, blocks: line == 2 ? [] : [ParsedBlock(sourceLine: line, kind: .paragraph(text))])
            }
            let list = ParsedList(isOrdered: isOrdered, startIndex: 1, items: items)
            return PreviewRows.rows(for: [ParsedBlock(sourceLine: 0, kind: .list(list))], maxWeight: 0)
        }
        let bullets = rowsOfList(false)
        try #require(bullets.count == 3)
        #expect(bullets[1].chrome.decorations == [.listItem(.bullet, showsMarker: true)])
        #expect(bullets.map(\.sourceLine) == bullets.map(\.sourceLine).sorted())

        let numbers = rowsOfList(true)
        try #require(numbers.count == 3)
        #expect(numbers.map(\.chrome.decorations) == (1...3).map { [.listItem(.number($0), showsMarker: true)] })
    }

    /// The viewer parse gives an empty task item an empty paragraph, so it keeps its checkbox.
    /// The marker needs a space after "]", or "[ ]" is plain text.
    @Test func emptyTaskItemKeepsItsCheckbox() throws {
        let result = splitRows("- [ ] a\n- [ ] \n- [x] c")
        try #require(result.count == 3)
        #expect(result[1].chrome.decorations == [.listItem(.checkbox(isChecked: false), showsMarker: true)])
    }

    /// The checkbox label is the row's own text, read when the row is drawn.
    @Test func checkboxLabelIsTheRowText() throws {
        let result = splitRows("- [ ] Buy milk\n- [x] **Call** Anna")
        try #require(result.count == 2)
        #expect(result.map(\.checkboxLabel) == ["Buy milk", "Call Anna"])
    }
}
