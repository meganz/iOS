import Foundation
@testable import MEGAMarkdown
import Testing

/// Big inputs parsed in the normal test run. These check structure only; timing lives in `ParsingBenchTests`.
@Suite struct ParsingLargeInputTests {
    /// Builds a mixed document of roughly `targetBytes` UTF-8 bytes.
    static func makeLargeDocument(targetBytes: Int) -> String {
        let section = """
        ## Section heading

        A paragraph with **bold**, *italic*, `code`, ~~strike~~ and a [link](https://mega.io).
        It continues on a second line so there is a soft break.

        - item one
        - item two
          - nested item
        1. first
        2. second

        > A quote with *emphasis*.

        ```swift
        let value = 42
        print(value)
        ```

        | A | B |
        |---|:-:|
        | 1 | 2 |

        ---


        """
        let count = targetBytes / section.utf8.count + 1
        return String(repeating: section, count: count)
    }

    @Test func parseTwoMegabytes() {
        let markdown = Self.makeLargeDocument(targetBytes: 2_000_000)
        let document = MarkdownParser.parse(markdown)
        // Each section has 8 top-level blocks (the bullet and ordered lists are separate lists).
        #expect(document.blocks.count % 8 == 0)
        #expect(document.blocks.count > 1_000)
        // No section may be lost or merged: the count and the order of kinds match the input.
        let sections = markdown.components(separatedBy: "## Section heading").count - 1
        #expect(document.blocks.count == sections * 8)
        let kinds = document.blocks.prefix(8).map(Self.kindName)
        #expect(kinds == ["heading", "paragraph", "list", "list", "quote", "code", "table", "break"])
        #expect(document.blocks.suffix(8).map(Self.kindName) == kinds)
    }

    static func kindName(_ block: MarkdownBlock) -> String {
        switch block.kind {
        case .heading: "heading"
        case .paragraph: "paragraph"
        case .list: "list"
        case .codeBlock: "code"
        case .blockQuote: "quote"
        case .table: "table"
        case .thematicBreak: "break"
        case .image: "image"
        }
    }

    @Test func parseOffMainThread() async {
        let document = await Task.detached {
            MarkdownParser.parse("# Title\n\n- a\n- b")
        }.value
        #expect(document.blocks.count == 2)
        #expect(document.blocks.first?.heading?.text == "Title")
        #expect(document.blocks.last?.list?.items.map { $0.blocks.first?.paragraphText } == ["a", "b"])
    }
}
