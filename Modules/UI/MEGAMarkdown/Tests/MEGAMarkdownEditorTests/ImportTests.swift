@testable import MEGAMarkdownEditor
import Testing

@Suite("Markdown import")
struct ImportTests {
    @Test func blockKinds() {
        let blocks = loadedBlocks("# Title\n\ntext\n\n- a\n  - b\n1. c\n\n> q\n\n```swift\nlet x\n```\n\n---\n")
        #expect(blocks == [
            heading(1, "Title"),
            paragraph("text"),
            bullet("a"),
            bullet("b", indent: 1),
            ordered("c"),
            quote("q"),
            .codeBlock(language: "swift", code: "let x"),
            .thematicBreak
        ])
    }

    @Test func softBreakStaysANewlineAndHardBreakBecomesALineSeparator() {
        #expect(loadedBlocks("a\nb  \nc\\\nd\n") == [paragraph("a\nb\u{2028}c\u{2028}d")])
    }

    @Test func inlineStyles() {
        #expect(loadedBlocks("**b** *i* ~~s~~ `c` <u>u</u> [l](https://x \"t\")\n") == [paragraph(
            "b i s c u l",
            (0..<1, .bold), (2..<3, .italic), (4..<5, .strikethrough), (6..<7, .code), (8..<9, .underline),
            (10..<11, link("https://x", title: "t"))
        )])
    }

    @Test func codeInsideALinkIsKept() {
        #expect(loadedBlocks("[`code` text](u)\n") == [paragraph("code text", (0..<4, .code), (0..<9, link("u")))])
    }

    @Test func tasksAndStartNumbers() {
        #expect(loadedBlocks("- [ ] a\n- [x] b\n") == [task("a"), task("b", checked: true)])
        #expect(loadedBlocks("7. a\n8. b\n") == [ordered("a", start: 7), ordered("b")])
    }

    @Test func emptyItemsAndHeadingsStayEditable() {
        #expect(loadedBlocks("- a\n-\n- b\n") == [bullet("a"), bullet(""), bullet("b")])
        #expect(loadedBlocks("#\n") == [heading(1, "")])
    }

    @Test func codeKeepsBlankLinesBeforeTheFence() {
        #expect(loadedBlocks("```\na\n\n```\n") == [.codeBlock(language: nil, code: "a\n")])
    }

    @Test func unsupportedBlocksStayRawByteForByte() {
        let table = "| a | b |\n|---|---|\n| 1 | 2 |"
        #expect(loadedBlocks("\(table)\n\ntext\n") == [.rawSource(table), paragraph("text")])
        #expect(loadedBlocks("<div>\nhi\n</div>\n") == [.rawSource("<div>\nhi\n</div>")])
        #expect(loadedBlocks("![alt](i.png)\n") == [.rawSource("![alt](i.png)")])
        // A list item with two paragraphs.
        #expect(loadedBlocks("- a\n\n  b\n") == [.rawSource("- a\n\n  b")])
    }

    @Test func neighbourRawBlocksJoinWithTheirSpacing() {
        #expect(loadedBlocks("<div>a</div>\n\n\n| x |\n|---|\n") == [.rawSource("<div>a</div>\n\n\n| x |\n|---|")])
    }

    @Test func referenceLinksResolveAndTheirDefinitionsStay() {
        let blocks = loadedBlocks("see [a][r]\n\n[r]: https://x\n")
        #expect(blocks == [paragraph("see a", (4..<5, link("https://x"))), .rawSource("[r]: https://x")])
    }

    @Test func definitionBlocksAreCollected() {
        let document = RichMarkdownConverter.document(from: "| [a][r] |\n|---|\n\n[r]: https://x\n\ntext\n\n[s]: /y \"t\"\n")
        #expect(document.referenceDefinitionSource == "[r]: https://x\n\n[s]: /y \"t\"")
        // A table cell, text, a converted paragraph and code are not definitions.
        let others: [RichBlock] = [.rawSource("| a |\n|---|"), .rawSource("[x] text"), paragraph("[r]: /z"), .rawSource("```\n[c]: /code\n```")]
        #expect(RichDocument(blocks: others).referenceDefinitionSource == "")
    }

    @Test func aDefinitionInsideAListKeepsTheListRaw() {
        #expect(loadedBlocks("- a\n- [r]: /u\n- b\n") == [.rawSource("- a\n- [r]: /u\n- b")])
    }

    @Test func frontMatterStaysRaw() {
        #expect(loadedBlocks("---\ntitle: x\n---\n# H\n") == [.rawSource("---\ntitle: x\n---"), heading(1, "H")])
    }

    @Test func twoListsOfOneKindStayApart() {
        #expect(loadedBlocks("- a\n\n* b\n") == [bullet("a"), paragraph(""), bullet("b")])
        // The first list ends with a nested item of another kind. Its top level decides.
        #expect(loadedBlocks("- a\n  1. n\n\n* b\n") == [bullet("a"), ordered("n", indent: 1), paragraph(""), bullet("b")])
        #expect(loadedBlocks("> a\n\n> b\n") == [quote("a"), paragraph(""), quote("b")])
    }

    @Test func fileFormatIsKept() {
        let crlf = RichMarkdownConverter.load("a\r\nb\r\n")
        #expect(crlf.document.format == RichFileFormat(lineEnding: .crlf, hasByteOrderMark: false, endsWithLineEnding: true))
        #expect(crlf.exported == "a\r\nb\r\n")
        let bom = RichMarkdownConverter.load("\u{FEFF}# T")
        #expect(bom.document.format == RichFileFormat(lineEnding: .lf, hasByteOrderMark: true, endsWithLineEnding: false))
        #expect(bom.document.blocks == [heading(1, "T")])
        #expect(bom.exported == "\u{FEFF}# T")
        #expect(RichMarkdownConverter.load("x\ry\r").exported == "x\ry\r")
    }

    @Test func emptyTextLoadsNoBlocks() {
        let loaded = RichMarkdownConverter.load("")
        #expect(loaded.document.blocks.isEmpty)
        #expect(loaded.exported == "")
    }

    @Test func aDeepQuoteStaysRaw() {
        let deep = String(repeating: "> ", count: 70) + "x"
        #expect(loadedBlocks(deep) == [.rawSource(deep)])
    }
}
