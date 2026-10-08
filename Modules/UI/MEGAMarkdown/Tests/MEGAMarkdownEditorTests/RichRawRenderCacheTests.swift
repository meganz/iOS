import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing

@Suite struct RichRawRenderCacheTests {
    private typealias RawRow = RichRawRenderCache.RawRow

    private static let table = "| A |\n|---|\n| [a][r] |"
    private static let definition = "[r]: https://mega.nz"

    private func firstCellLinks(_ rows: [PreviewRow]?) -> [String] {
        guard case .tablePage(let table, _, _, _)? = rows?.first?.content else { return [] }
        return table.rows.first?.first?.links.map(\.url) ?? []
    }

    private func id(_ value: Int) -> RichRowID {
        RichRowID(value: value)
    }

    @Test func changeWithoutRawRowsReadsNoDefinitions() {
        var cache = RichRawRenderCache(raw: [RawRow(id: id(1), source: Self.table)], rows: [:], definitions: "")
        var reads = 0
        let update = cache.update(removing: [id(0)], adding: [], allRaw: { [] }, definitions: { reads += 1; return "" })
        #expect(update == .kept)
        #expect(reads == 0)
    }

    @Test func newRawRowIsRenderedWithTheSameDefinitions() {
        var cache = RichRawRenderCache(raw: [RawRow(id: id(1), source: Self.definition)], rows: [:], definitions: Self.definition)
        let update = cache.update(removing: [], adding: [RawRow(id: id(2), source: Self.table)],
                                  allRaw: { [] }, definitions: { Self.definition })
        #expect(update == .kept)
        #expect(firstCellLinks(cache.previewRows(for: id(2))) == ["https://mega.nz"])
        #expect(cache.previewRows(for: id(1)) == [])
        #expect(cache.itemCount(for: id(1)) == 1)
    }

    /// A new definition changes how other raw rows read, so every raw row renders again.
    @Test func newDefinitionsRenderEveryRawRow() {
        var cache = RichRawRenderCache(raw: [RawRow(id: id(1), source: Self.table)], rows: [:], definitions: "")
        #expect(firstCellLinks(cache.previewRows(for: id(1))).isEmpty)
        let all = [RawRow(id: id(1), source: Self.table), RawRow(id: id(2), source: Self.definition)]
        let update = cache.update(removing: [], adding: [all[1]], allRaw: { all }, definitions: { Self.definition })
        #expect(update == .renderedAll)
        #expect(firstCellLinks(cache.previewRows(for: id(1))) == ["https://mega.nz"])
        #expect(cache.definitions == Self.definition)
    }

    /// A replace keeps identities in order, so an identity can come back with another source.
    @Test func reusedIdentityWithNewSourceRendersAgain() {
        var cache = RichRawRenderCache(raw: [RawRow(id: id(1), source: "<div>a</div>")], rows: [:], definitions: "")
        let update = cache.update(removing: [id(1)], adding: [RawRow(id: id(1), source: Self.table)],
                                  allRaw: { [] }, definitions: { "" })
        #expect(update == .kept)
        guard case .tablePage? = cache.previewRows(for: id(1))?.first?.content else {
            Issue.record("the old source is still shown")
            return
        }
    }

    @Test func removedRawRowLeavesTheCache() {
        var cache = RichRawRenderCache(raw: [RawRow(id: id(1), source: Self.table)], rows: [:], definitions: "")
        _ = cache.update(removing: [id(1)], adding: [], allRaw: { [] }, definitions: { "" })
        #expect(cache.previewRows(for: id(1)) == nil)
    }

    @Test func largeTableTakesOneItemPerPage() {
        let table = "| a |\n|---|\n" + (0..<120).map { "| \($0) |" }.joined(separator: "\n")
        let cache = RichRawRenderCache(raw: [RawRow(id: id(1), source: table)], rows: [:], definitions: "")
        #expect(cache.itemCount(for: id(1)) == 3)
    }
}
