import Foundation
@testable import MEGAMarkdown
import Testing

@Suite struct ParsingTableTests {
    @Test func basicTable() throws {
        let table = try #require(parse("| Name | Size |\n|---|---|\n| a.txt | 1 KB |\n| b.md | 2 KB |").first?.table)
        #expect(table.columns.count == 2)
        #expect(table.header.map(\.plain) == ["Name", "Size"])
        #expect(table.rows.map { $0.map(\.plain) } == [["a.txt", "1 KB"], ["b.md", "2 KB"]])
    }

    @Test func columnAlignment() throws {
        // Quirk: a column with no colon is reported as `.left` by Foundation, so `.none` never appears.
        let table = try #require(parse("| a | b | c | d |\n|:--|:-:|--:|---|\n| 1 | 2 | 3 | 4 |").first?.table)
        #expect(table.columns.map(\.alignment) == [.left, .center, .right, .left])
    }

    @Test func raggedRowsArePadded() throws {
        // Quirk: `tableRow` ordinals start at 1; a missing cell produces no run at all.
        let table = try #require(parse("| a | b | c |\n|---|---|---|\n| 1 |\n| 1 | 2 | 3 | 4 |").first?.table)
        #expect(table.rows.count == 2)
        #expect(table.rows[0].map(\.plain) == ["1", "", ""])
        // Extra cells beyond the header are dropped by GFM.
        #expect(table.rows[1].map(\.plain) == ["1", "2", "3"])
    }

    @Test func emptyCellInMiddle() throws {
        let table = try #require(parse("| a | b | c |\n|---|---|---|\n| 1 |   | 3 |").first?.table)
        #expect(table.rows[0].map(\.plain) == ["1", "", "3"])
    }

    @Test func inlineStylesInCells() throws {
        let table = try #require(parse("| **h** |\n|---|\n| `c` [l](https://a.b) |").first?.table)
        #expect(table.header[0].plain == "h")
        #expect(table.header[0].runs.first?.inlinePresentationIntent == .stronglyEmphasized)
        #expect(table.rows[0][0].plain == "c l")
        #expect(table.rows[0][0].runs.contains { $0.link != nil })
    }

    @Test func headerOnlyTable() throws {
        let table = try #require(parse("| a | b |\n|---|---|").first?.table)
        #expect(table.header.map(\.plain) == ["a", "b"])
        #expect(table.rows.isEmpty)
    }

    @Test func twoTablesStaySeparate() {
        let blocks = parse("| a |\n|---|\n| 1 |\n\ntext\n\n| b |\n|---|\n| 2 |")
        #expect(blocks.count == 3)
        #expect(blocks[0].table?.rows.first?.first?.plain == "1")
        #expect(blocks[2].table?.rows.first?.first?.plain == "2")
    }

    /// A dropped empty row must not shift the source lines of the rows after it.
    @Test func keptRowsKeepTheirSourceLines() throws {
        let markdown = "| a | b |\n|---|---|\n| 1 | 2 |\n| | |\n| 3 | 4 |\n\n> | c |\n> |---|\n> | |\n> | 5 |"
        let blocks = try #require(CmarkParser.blocks(markdown, softBreak: .lineBreak))
        let first = try #require(parsedTable(blocks[0]))
        #expect(first.rows.map { $0.map(\.text) } == [["1", "2"], ["3", "4"]])
        #expect(first.rowLines == [2, 4])
        let quoted = try #require(blocks[1].kind.quoteBlocks?.first.flatMap(parsedTable))
        #expect(quoted.rows.map { $0.map(\.text) } == [["5"]])
        #expect(quoted.rowLines == [9])
    }

    @Test func rowLinesFollowTheChunkLineOffset() throws {
        var body = "| a |\n|---|\n| 1 |\n| 2 |"
        let blocks = try #require(body.withUTF8 { buffer in
            CmarkParser.blocks(prefix: [], body: buffer, softBreak: .lineBreak, lineOffset: 100, lastLine: 0)?.blocks
        })
        #expect(try #require(parsedTable(blocks[0])).rowLines == [102, 103])
    }

    private func parsedTable(_ block: ParsedBlock) -> ParsedTable? {
        if case .table(let table) = block.kind { return table }
        return nil
    }
}

private extension ParsedBlock.Kind {
    var quoteBlocks: [ParsedBlock]? {
        if case .blockQuote(let blocks) = self { return blocks }
        return nil
    }
}
