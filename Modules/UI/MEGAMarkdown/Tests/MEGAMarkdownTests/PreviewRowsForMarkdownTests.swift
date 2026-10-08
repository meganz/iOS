@testable import MEGAMarkdown
import Testing

/// Rows of a small Markdown string, as a view shows one raw block alone.
struct PreviewRowsForMarkdownTests {
    private static let table = "| A |\n|---|\n| [a][r] |"

    private static func firstCell(_ rows: [PreviewRow]) throws -> InlineText {
        let row = try #require(rows.first)
        guard case .tablePage(let table, _, _, _) = row.content else {
            Issue.record("not a table row: \(row.content)")
            return InlineText()
        }
        return try #require(table.rows.first?.first)
    }

    /// A raw block in the editor shows the same rows as the preview shows for the same Markdown.
    @Test func rowsSplitLikeThePreview() {
        let markdown = """
            # Title

            Some *text*.

            - one
              - two
                1. three
            > quote
            > > inner

            ```swift
            let a = 1
            ```

            | A | B |
            |---|---|
            | 1 | 2 |

            ---
            """
        var preview: [PreviewRow] = []
        _ = PreviewPipeline.parse(MarkdownParseRequest(markdown: markdown), limits: PreviewParseLimits()) { preview += $0.rows }
        let rows = PreviewRows.rows(forMarkdown: markdown, softBreak: MarkdownParseRequest(markdown: markdown).softBreak)
        #expect(rows.count > 8)
        #expect(rows == preview)
    }

    /// The definitions come from outside the Markdown and turn `[a][r]` into a link.
    @Test func definitionsResolveReferenceLinks() throws {
        let rows = PreviewRows.rows(forMarkdown: Self.table, softBreak: .lineBreak, definitions: "[r]: https://mega.nz")
        #expect(rows.count == 1)
        #expect(rows.first?.sourceLine == 0)
        let cell = try Self.firstCell(rows)
        #expect(cell.text == "a")
        #expect(cell.links.map(\.url) == ["https://mega.nz"])
        #expect(cell.runs.map(\.link) == [0])
    }

    @Test func withoutDefinitionsTheReferenceStaysText() throws {
        let cell = try Self.firstCell(PreviewRows.rows(forMarkdown: Self.table, softBreak: .lineBreak))
        #expect(cell.text == "[a][r]")
        #expect(cell.links.isEmpty)
        #expect(cell.runs.allSatisfy { $0.link < 0 })
    }

    /// Source lines count from the Markdown, not from the definitions in front of it.
    @Test func sourceLinesIgnoreTheDefinitions() {
        let rows = PreviewRows.rows(forMarkdown: "one\n\ntwo", softBreak: .lineBreak, definitions: "[r]: /a\n[s]: /b\n")
        #expect(rows.map(\.sourceLine) == [0, 2])
    }

    /// Markdown that shows nothing gives no rows, with or without definitions.
    @Test(arguments: ["[r]: https://mega.nz", "[r]: /a\n[s]: /b \"title\"", "", "  \n\n \t\n"])
    func markdownThatShowsNothingGivesNoRows(markdown: String) {
        #expect(PreviewRows.rows(forMarkdown: markdown, softBreak: .lineBreak).isEmpty)
        #expect(PreviewRows.rows(forMarkdown: markdown, softBreak: .lineBreak, definitions: "[q]: /q").isEmpty)
    }

    /// The preview shows HTML blocks as their source text, also a comment or an empty element. So they give a row.
    @Test(arguments: ["<!-- a comment -->", "<div>\n</div>"])
    func htmlBlocksShowTheirSource(markdown: String) throws {
        let rows = PreviewRows.rows(forMarkdown: markdown, softBreak: .lineBreak)
        #expect(rows.count == 1)
        let row = try #require(rows.first)
        guard case .textPiece(let text, headingLevel: nil, isFirst: true) = row.content else {
            Issue.record("not a paragraph row: \(row.content)")
            return
        }
        #expect(text.text == markdown + "\n")
        #expect(text.runs.map(\.style) == [.blockHTML])
    }
}
