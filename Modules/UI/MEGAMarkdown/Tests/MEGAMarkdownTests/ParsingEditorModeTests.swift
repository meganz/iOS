@testable import MEGAMarkdown
import Testing

/// `ParseMode.editor` keeps what the viewer drops, so an editor that writes Markdown back loses no line.
@Suite("Editor parse mode")
struct ParsingEditorModeTests {
    private func editor(_ markdown: String) -> [ParsedBlock] {
        CmarkParser.editorBlocks(markdown)?.blocks ?? []
    }

    private func viewer(_ markdown: String) -> [ParsedBlock] {
        CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? []
    }

    @Test func emptyHeadingStays() {
        #expect(viewer("#\n").isEmpty)
        #expect(editor("#\n").map(\.kind) == [.heading(level: 1, text: InlineText())])
    }

    @Test func emptyListItemStays() {
        guard case .list(let list)? = editor("- a\n-\n- b\n").first?.kind else {
            Issue.record("no list")
            return
        }
        #expect(list.items.count == 3)
        #expect(list.items[1].blocks.isEmpty)
        guard case .list(let viewerList)? = viewer("- a\n-\n- b\n").first?.kind else { return }
        #expect(viewerList.items.count == 2)
    }

    @Test func emptyCodeBlockAndTrailingBlankLinesStay() {
        #expect(viewer("```\n```\n").isEmpty)
        #expect(editor("```\n```\n").map(\.kind) == [.codeBlock(language: nil, code: "")])
        #expect(editor("```\na\n\n```\n").map(\.kind) == [.codeBlock(language: nil, code: "a\n")])
        #expect(viewer("```\na\n\n```\n").map(\.kind) == [.codeBlock(language: nil, code: "a")])
    }

    @Test func codeBlockOfOnlyBlankLinesStaysForTheEditorAndGoesForTheViewer() {
        #expect(editor("```\n\n\n```\n").map(\.kind) == [.codeBlock(language: nil, code: "\n")])
        #expect(viewer("```\n\n\n```\n").isEmpty)
    }

    @Test func emptyQuoteStays() {
        #expect(viewer(">\n").isEmpty)
        #expect(editor(">\n").map(\.kind) == [.blockQuote([])])
    }

    @Test func imageInsideALinkKeepsTheImageStyle() throws {
        guard case .paragraph(let text)? = editor("a [![alt](i.png)](u)\n").first?.kind else {
            Issue.record("no paragraph")
            return
        }
        // "a " is plain. The alt text runs carry the image style. The viewer gives them none (rule R3).
        #expect(text.runs.map { $0.style.contains(.image) } == [false, true])
        guard case .paragraph(let viewerText)? = viewer("a [![alt](i.png)](u)\n").first?.kind else { return }
        #expect(viewerText.runs.allSatisfy { !$0.style.contains(.image) })
    }

    @Test func topLevelBlocksComeWithTheirLines() throws {
        let parsed = try #require(CmarkParser.editorBlocks(">\n> a\n\npara\nnext\n\n-\n  b\n"))
        #expect(parsed.lines == [0...1, 3...4, 6...7])
        #expect(parsed.blocks.count == 3)
    }

    @Test(arguments: [
        ("a\n===\n", [0...1]),
        ("```\na\n```\n", [0...2]),
        ("a\n\n---\n", [0...0, 2...2]),
        ("| a |\n|---|\n| b |\n", [0...2]),
        ("- a\n  - b\n- c\n", [0...2]),
        (">\n", [0...0]),
        ("<div>\nx\n</div>\n", [0...2])
    ])
    func topLevelLinesCoverEachBlockKind(markdown: String, expected: [ClosedRange<Int>]) throws {
        #expect(try #require(CmarkParser.editorBlocks(markdown)).lines == expected)
    }

    @Test func listStartingWithAnEmptyItemKeepsIt() {
        guard case .list(let list)? = editor("-\n- a\n").first?.kind else {
            Issue.record("no list")
            return
        }
        #expect(list.items.count == 2)
        #expect(list.items[0].blocks.isEmpty)
        guard case .list(let viewerList)? = viewer("-\n- a\n").first?.kind else { return }
        #expect(viewerList.items.count == 1)
    }

    @Test func orderedListWithAnEmptyFirstItemKeepsItsStart() {
        guard case .list(let list)? = editor("3.\n4. a\n").first?.kind else {
            Issue.record("no list")
            return
        }
        #expect(list.isOrdered)
        #expect(list.startIndex == 3)
        #expect(list.items.count == 2)
    }

    @Test func emptyItemInsideAnItemStays() {
        guard case .list(let outer)? = editor("- a\n\n  -\n  - c\n").first?.kind,
              case .list(let inner)? = outer.items.first?.blocks.last?.kind else {
            Issue.record("no nested list")
            return
        }
        #expect(inner.items.count == 2)
        #expect(inner.items[0].blocks.isEmpty)
    }
}
