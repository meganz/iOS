import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing

@Suite struct RichEditorLoadTests {
    private func loaded(_ markdown: String) throws -> RichEditorLoad {
        guard case .loaded(let load) = RichEditorLoad.make(markdown) else {
            Issue.record("the load was refused")
            throw CancellationError()
        }
        return load
    }

    @Test func blockAtTheLimitLoads() throws {
        let load = try loaded(String(repeating: "a", count: RichEditorLoad.maxBlockLength))
        #expect(load.editor.rows.count == 1)
    }

    @Test func blockOverTheLimitIsRefused() {
        let paragraph = String(repeating: "a", count: RichEditorLoad.maxBlockLength + 1)
        guard case .blockTooLong(let units) = RichEditorLoad.make("# Title\n\n" + paragraph) else {
            Issue.record("the load was not refused")
            return
        }
        #expect(units == RichEditorLoad.maxBlockLength + 1)
    }

    @Test func codeOverTheLimitIsRefused() {
        let code = "```\n" + String(repeating: "abcdefghi\n", count: RichEditorLoad.maxBlockLength / 10 + 1) + "```\n"
        guard case .blockTooLong = RichEditorLoad.make(code) else {
            Issue.record("the load was not refused")
            return
        }
    }

    /// Raw blocks render in pieces, so a long raw block does not count.
    @Test func longRawBlockLoads() throws {
        let table = "| a |\n|---|\n" + (0..<20_000).map { "| row \($0) |" }.joined(separator: "\n")
        let load = try loaded(table)
        #expect(load.editor.rows.count == 1)
        let rows = try #require(load.rawRows[load.editor.rows[0].id])
        // 20,000 table rows in pages of 50.
        #expect(rows.count == 400)
    }

    @Test func metricsCoverEveryRow() throws {
        let load = try loaded("# Title\n\nSome text.\n\n```swift\na\nb\n```\n\n---\n\n| a |\n|---|\n| b |\n")
        #expect(load.metrics == [
            .text(bytes: 5, headingLevel: 1),
            .text(bytes: 10, headingLevel: nil),
            .code(lines: 2, hasLanguage: true),
            .divider,
            .raw
        ])
    }

    /// A raw table resolves references with the definitions of the whole file.
    /// A definitions-only raw block shows nothing, so its rows are empty.
    @Test func rawRowsUseTheDefinitionsOfTheFile() throws {
        let load = try loaded("| A |\n|---|\n| [a][r] |\n\nText.\n\n[r]: https://mega.nz\n")
        #expect(load.definitions.contains("[r]: https://mega.nz"))
        let rawIDs = load.editor.rows.filter(\.block.isRawSource).map(\.id)
        try #require(rawIDs.count == 2)
        let tableRows = try #require(load.rawRows[rawIDs[0]])
        guard case .tablePage(let table, _, _, _) = tableRows.first?.content else {
            Issue.record("not a table row")
            return
        }
        #expect(table.rows.first?.first?.links.map(\.url) == ["https://mega.nz"])
        #expect(load.rawRows[rawIDs[1]] == [])
    }

    @Test func fileWithoutRawBlocksHasNoDefinitions() throws {
        let load = try loaded("text")
        #expect(load.definitions.isEmpty)
        #expect(load.rawRows.isEmpty)
    }
}
