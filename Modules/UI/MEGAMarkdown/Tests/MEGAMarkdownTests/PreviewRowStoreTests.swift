@testable import MEGAMarkdown
import Testing

@MainActor
@Suite struct PreviewRowStoreTests {
    private static func row(line: Int, notice: Bool = false) -> PreviewRow {
        var text = InlineText()
        text.append("Line \(line)", style: [])
        let content: PreviewRow.Content = notice ? .notice(.shownAsPlainText) : .textPiece(text, headingLevel: nil, isFirst: true)
        return PreviewRow(sourceLine: line, content: content)
    }

    /// Lines 0, 2, 2, 5, 9, ... in parts of 3, 0, 1 and 6 rows.
    private static let lines = [0, 2, 2, 5, 9, 9, 9, 12, 20, 21]

    private static func makeStore() -> (PreviewRowStore, [PreviewRow]) {
        let rows = lines.enumerated().map { row(line: $1, notice: $0 == 3) }
        let store = PreviewRowStore()
        for part in [0..<3, 3..<3, 3..<4, 4..<10] {
            store.append(Array(rows[part]))
        }
        return (store, rows)
    }

    @Test func subscriptReadsAcrossParts() {
        let (store, rows) = Self.makeStore()
        #expect(store.count == rows.count)
        #expect(rows.indices.map { store[$0] } == rows)
        #expect(store.last == rows.last)
        #expect(store.noticeRows == [3])
    }

    @Test func rowIndexMatchesTheArrayLookup() {
        let (store, rows) = Self.makeStore()
        for line in -1...25 {
            #expect(store.rowIndex(containing: line) == rowIndex(containing: line, in: rows), "line \(line)")
        }
        #expect(store.rowIndex(containing: 9) == 6)
        #expect(store.rowIndex(containing: 100) == 9)
    }

    @Test func emptyStoreHasNoRows() {
        let store = PreviewRowStore()
        store.append([])
        #expect(store.isEmpty)
        #expect(store.last == nil)
        #expect(store.rowIndex(containing: 0) == nil)
    }
}
