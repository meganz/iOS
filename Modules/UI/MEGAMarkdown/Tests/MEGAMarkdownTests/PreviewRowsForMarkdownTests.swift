@testable import MEGAMarkdown
import Testing

/// Rows of a small Markdown string, as a view shows one raw block alone.
struct PreviewRowsForMarkdownTests {
    /// A caller that shows one block alone gets the same rows as the preview for the same Markdown.
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

    /// Markdown that shows nothing gives no rows.
    @Test(arguments: ["[r]: https://mega.nz", "[r]: /a\n[s]: /b \"title\"", "", "  \n\n \t\n"])
    func markdownThatShowsNothingGivesNoRows(markdown: String) {
        #expect(PreviewRows.rows(forMarkdown: markdown, softBreak: .lineBreak).isEmpty)
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
