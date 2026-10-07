@testable import MEGAMarkdownEditor
import Testing

@Suite("Markdown export")
struct ExportTests {
    @Test func blockSyntax() {
        let blocks: [RichBlock] = [
            heading(2, "Title"), paragraph("text"), bullet("a"), bullet("b", indent: 1), ordered("c", start: 3), ordered("d"),
            task("e", checked: true), quote("q"), quote("qq", depth: 2), .codeBlock(language: "swift", code: "let x"), .thematicBreak
        ]
        #expect(exportedBody(blocks) == """
        ## Title

        text

        - a
          - b

        3. c
        4. d

        - [x] e

        > q
        >
        > > qq

        ```swift
        let x
        ```

        ---
        """)
    }

    @Test func plainTextIsEscaped() {
        #expect(exportedBody([paragraph("a*b_c `d` [e] <f> |g| ~h \\ &amp;")]) == "a\\*b\\_c \\`d\\` \\[e\\] \\<f> \\|g\\| \\~h \\\\ \\&amp;")
    }

    @Test func syntaxWithACombiningMarkIsEscaped() {
        let blocks = [paragraph(">\u{301} *\u{301}x*")]
        #expect(exportedBody(blocks) == "\\>\u{301} \\*\u{301}x\\*")
        #expect(loadedBlocks(exportedBody(blocks)) == blocks)
    }

    @Test func lineStartSyntaxIsEscaped() {
        #expect(exportedBody([paragraph("# no")]) == "\\# no")
        #expect(exportedBody([paragraph("- no\n+ no\n> no\n= no")]) == "\\- no\n\\+ no\n\\> no\n\\= no")
        #expect(exportedBody([paragraph("12. no\n3) no\n4.5 yes")]) == "12\\. no\n3\\) no\n4.5 yes")
    }

    @Test func bareLinksStayPlainText() {
        let markdown = exportedBody([paragraph("see https://mega.nz and www.mega.nz")])
        #expect(markdown == "see https\\://mega.nz and www\\.mega.nz")
        #expect(loadedBlocks(markdown) == [paragraph("see https://mega.nz and www.mega.nz")])
    }

    /// cmark joins text nodes before it looks for email addresses, so no escape can keep one plain.
    @Test func aPlainEmailAddressBecomesALinkOnReload() {
        let markdown = exportedBody([paragraph("mail a@b.co")])
        #expect(loadedBlocks(markdown) == [paragraph("mail a@b.co", (5..<11, link("mailto:a@b.co")))])
    }

    @Test func inlineStyles() {
        #expect(exportedBody([paragraph("b i s c u", (0..<1, .bold), (2..<3, .italic), (4..<5, .strikethrough), (6..<7, .code), (8..<9, .underline))])
            == "**b** *i* ~~s~~ `c` <u>u</u>")
    }

    @Test func stylesThatCannotUseMarkersUseTags() {
        // Bold on only the code inside a word: `**` cannot open after a letter and before a backtick.
        let blocks = [paragraph("ace", (1..<2, .bold), (1..<2, .code))]
        let markdown = exportedBody(blocks)
        #expect(markdown.contains("<strong>"))
        #expect(loadedBlocks(markdown) == blocks)
    }

    @Test func links() {
        #expect(exportedBody([paragraph("a", (0..<1, link("https://x")))]) == "[a](https://x)")
        #expect(exportedBody([paragraph("a", (0..<1, link("https://x", title: "t \"q\"")))]) == "[a](https://x \"t \\\"q\\\"\")")
        #expect(exportedBody([paragraph("a", (0..<1, link("with space")))]) == "[a](<with space>)")
        #expect(exportedBody([paragraph("a", (0..<1, link("p(x)")))]) == "[a](p\\(x\\))")
        #expect(exportedBody([paragraph("a", (0..<1, link("")))]) == "[a](<>)")
        #expect(exportedBody([paragraph("a", (0..<1, link("&copy;")))]) == "[a](&amp;copy;)")
    }

    @Test func aLinkWhoseTextIsTheURLIsAnAutolink() {
        #expect(exportedBody([paragraph("https://mega.nz", (0..<15, link("https://mega.nz")))]) == "<https://mega.nz>")
        #expect(exportedBody([paragraph("a@b.co", (0..<6, link("mailto:a@b.co")))]) == "<a@b.co>")
    }

    @Test func codeInsideALink() {
        let blocks = [paragraph("code text", (0..<4, .code), (0..<9, link("u")))]
        #expect(exportedBody(blocks) == "[`code` text](u)")
        #expect(loadedBlocks(exportedBody(blocks)) == blocks)
    }

    @Test func boldAcrossALinkEdgeIsCutAtTheEdge() {
        let blocks = [paragraph("abcdef", (0..<4, .bold), (2..<6, link("u")))]
        #expect(exportedBody(blocks) == "**ab**[**cd**ef](u)")
        #expect(loadedBlocks(exportedBody(blocks)) == blocks)
        // A cut piece that ends with a space cannot close `**`, so tags write it.
        let spaced = [paragraph("ab cd ef", (0..<5, .bold), (3..<8, link("u")))]
        #expect(exportedBody(spaced) == "<strong>ab </strong>[<strong>cd</strong> ef](u)")
        #expect(loadedBlocks(exportedBody(spaced)) == spaced)
    }

    @Test func anExclamationMarkBeforeALinkIsNotAnImage() {
        let blocks = [paragraph("Hey!link", (4..<8, link("u")))]
        #expect(exportedBody(blocks) == "Hey\\![link](u)")
        #expect(loadedBlocks(exportedBody(blocks)) == blocks)
    }

    @Test func breaks() {
        #expect(exportedBody([paragraph("a\nb\u{2028}c")]) == "a\nb\\\nc")
        #expect(exportedBody([bullet("a\nb")]) == "- a\n  b")
        #expect(exportedBody([quote("a\nb")]) == "> a\n> b")
    }

    @Test func spacesAtLineEdgesAreDropped() {
        #expect(exportedBody([paragraph("  a  \n  b ")]) == "a\nb")
        // Inside a code span the space is code, so it stays.
        #expect(exportedBody([paragraph(" a", (0..<2, .code))]) == "` a`")
    }

    @Test func codeOverABreakIsCutThere() {
        let markdown = exportedBody([paragraph("a\nb", (0..<3, .code))])
        #expect(markdown == "`a`\n`b`")
        #expect(loadedBlocks(markdown) == [paragraph("a\nb", (0..<1, .code), (2..<3, .code))])
    }

    @Test func headingBreaks() {
        #expect(exportedBody([heading(1, "a\nb")]) == "a\nb\n===")
        #expect(exportedBody([heading(2, "a\nb")]) == "a\nb\n---")
        #expect(exportedBody([heading(3, "a\nb")]) == "### a b")
        #expect(exportedBody([heading(1, "")]) == "#")
        #expect(exportedBody([heading(1, "C#")]) == "# C\\#")
    }

    @Test func codeFences() {
        #expect(exportedBody([.codeBlock(language: nil, code: "a ``` b")]) == "````\na ``` b\n````")
        #expect(exportedBody([.codeBlock(language: "a`b", code: "x")]) == "~~~a`b\nx\n~~~")
        #expect(exportedBody([.codeBlock(language: nil, code: "")]) == "```\n```")
    }

    @Test func emptyItemsAndTasks() {
        #expect(exportedBody([bullet("a"), bullet(""), bullet("b")]) == "- a\n-\n- b")
        #expect(exportedBody([task("")]) == "- [ ] ")
    }

    @Test func listsNextToEachOtherStayApart() {
        #expect(exportedBody([bullet("a"), paragraph(""), bullet("b")]) == "- a\n\n* b")
        #expect(exportedBody([ordered("a"), paragraph(""), ordered("b")]) == "1. a\n\n1) b")
        #expect(exportedBody([quote("a"), paragraph(""), quote("b")]) == "> a\n\n> b")
        // An empty quote row is not written, but it still ends the list: the shown numbers restart after it.
        #expect(exportedBody([ordered("a"), quote(""), ordered("b")]) == "1. a\n\n1) b")
    }

    @Test func nestedListsAfterText() {
        // An ordered list that does not start at 1 cannot interrupt the parent's text: a blank line comes first.
        #expect(exportedBody([bullet("a"), ordered("b", indent: 1, start: 3)]) == "- a\n\n  3. b")
        // `-` alone under text would make the text a heading.
        #expect(exportedBody([bullet("a"), bullet("", indent: 1)]) == "- a\n\n  -")
        // An empty parent would end at a blank line, so its children follow at once.
        #expect(exportedBody([bullet(""), ordered("b", indent: 1, start: 3)]) == "-\n  3. b")
    }

    @Test func rawSourceIsWrittenAsItIs() {
        #expect(exportedBody([.rawSource("| a |\n|---|"), paragraph("x")]) == "| a |\n|---|\n\nx")
    }

    @Test func emptyParagraphsAreNotWritten() {
        #expect(exportedBody([paragraph(""), paragraph("a"), paragraph("  ")]) == "a")
        // A space that is link text is written.
        #expect(exportedBody([paragraph(" ", (0..<1, link("u")))]) == "[ ](u)")
    }

    @Test func fileFormatIsWrittenBack() {
        let document = RichDocument(blocks: [paragraph("a"), paragraph("b")], format: RichFileFormat(lineEnding: .crlf, hasByteOrderMark: true, endsWithLineEnding: false))
        #expect(RichMarkdownConverter.markdown(from: document) == "\u{FEFF}a\r\n\r\nb")
    }

    @Test func theCacheGivesTheSameBytes() {
        let blocks = [paragraph("**a**", (0..<1, .bold)), bullet("b")]
        var cache = InlineExportCache()
        let first = RichMarkdownConverter.markdown(from: RichDocument(blocks: blocks), cache: &cache)
        let second = RichMarkdownConverter.markdown(from: RichDocument(blocks: blocks), cache: &cache)
        #expect(first == second)
        #expect(cache.pieces.count == 2)
    }
}
