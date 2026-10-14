@testable import MEGAMarkdownEditor
import Testing

@Suite("Copy")
struct CopyTests {
    private func copy(_ blocks: [RichBlock], _ range: RichSelection) -> RichClipboardContent? {
        RichClipboard.content(of: RichDocument(blocks: blocks), in: range)
    }

    @Test func aWholeBlockCopiesItsBlockMarkdown() {
        #expect(copy([heading(2, "Title")], selection(position(0, 0), position(0, 5)))
            == RichClipboardContent(plainText: "Title", markdown: "## Title"))
        #expect(copy([task("done", checked: true)], selection(position(0, 0), position(0, 4)))?.markdown == "- [x] done")
        #expect(copy([quote("q", depth: 2)], selection(position(0, 0), position(0, 1)))?.markdown == "> > q")
        #expect(copy([.codeBlock(language: "swift", code: "let a")], selection(position(0, 0), position(0, 5)))?.markdown == "```swift\nlet a\n```")
    }

    @Test func anOrderedItemKeepsItsShownNumber() {
        let blocks = [ordered("a"), ordered("b"), ordered("c")]
        #expect(copy(blocks, selection(position(2, 0), position(2, 1))) == RichClipboardContent(plainText: "3. c", markdown: "3. c"))
        #expect(copy(blocks, selection(position(1, 0), position(2, 1)))?.markdown == "2. b\n3. c")
    }

    @Test func aPartCopiesInlineMarkdownOnly() {
        let blocks: [RichBlock] = [.heading(level: 1, text: rich("hello world", (0..<5, .bold)))]
        #expect(copy(blocks, selection(position(0, 2), position(0, 8))) == RichClipboardContent(plainText: "llo wo", markdown: "**llo** wo"))
    }

    @Test func plainTextHasNoEscapes() {
        let content = copy([paragraph("file_name a\u{2028}b")], selection(position(0, 0), position(0, 5)))
        #expect(content == RichClipboardContent(plainText: "file_", markdown: "file\\_"))
        #expect(copy([paragraph("a\u{2028}b")], selection(position(0, 0), position(0, 3)))?.plainText == "a\nb")
    }

    @Test func blocksCopyWithTheirMarkers() {
        let blocks = [heading(1, "T"), bullet("a"), task("b", indent: 1), .thematicBreak, paragraph("p")]
        let content = copy(blocks, selection(position(0, 0), position(4, 1)))
        #expect(content?.plainText == "T\n- a\n  - [ ] b\n\np")
        #expect(content?.markdown == "# T\n\n- a\n  - [ ] b\n\n---\n\np")
    }

    @Test func endsOfASelectionKeepTheirKind() {
        let blocks = [bullet("one two"), paragraph("three four")]
        #expect(copy(blocks, selection(position(0, 4), position(1, 5)))?.markdown == "- two\n\nthree")
    }

    @Test func aCaretCopiesNothing() {
        #expect(copy([paragraph("a")], .caret(position(0, 1))) == nil)
    }
}

@Suite("Paste")
struct PasteTests {
    private func paste(_ markdown: String, into blocks: [RichBlock], at caret: RichPosition) -> RichEditor {
        var target = editor(blocks, caret: caret)
        target.paste(RichPasteContent(markdown: markdown))
        return target
    }

    @Test func aHeadingIntoAnEmptyParagraphReplacesIt() {
        let result = paste("## Title", into: [paragraph("")], at: position(0, 0))
        #expect(result.blocks == [heading(2, "Title")])
        #expect(result.selection == .caret(position(0, 5)))
    }

    @Test func inlineMarkdownJoinsTheTarget() {
        let result = paste("**b**", into: [paragraph("ac")], at: position(0, 1))
        #expect(result.blocks == [paragraph("abc", (1..<2, .bold))])
        #expect(result.selection == .caret(position(0, 2)))
    }

    @Test func paragraphsTakeTheKindOfAListTarget() {
        let result = paste("A\n\nB\n\nC", into: [bullet("item")], at: position(0, 4))
        #expect(result.blocks == [bullet("itemA"), bullet("B"), bullet("C")])
        #expect(result.selection == .caret(position(2, 1)))
    }

    @Test func otherBlocksKeepTheirKindAndTheTailFollows() {
        let result = paste("# H\n\ntext", into: [paragraph("xy")], at: position(0, 1))
        #expect(result.blocks == [paragraph("x"), heading(1, "H"), paragraph("texty")])
        #expect(result.selection == .caret(position(2, 4)))
    }

    @Test func aTableBecomesARawBlockWithAParagraphAfter() {
        let result = paste("| a |\n|---|\n| 1 |", into: [paragraph("")], at: position(0, 0))
        #expect(result.blocks == [.rawSource("| a |\n|---|\n| 1 |"), paragraph("")])
        #expect(result.selection == .caret(position(1, 0)))
    }

    @Test func codeAndListsKeepTheirKind() {
        #expect(paste("```swift\nlet a\n```", into: [paragraph("")], at: position(0, 0)).blocks == [.codeBlock(language: "swift", code: "let a")])
        #expect(paste("1. a\n2. b", into: [paragraph("")], at: position(0, 0)).blocks == [ordered("a"), ordered("b")])
        #expect(paste("5. a", into: [paragraph("")], at: position(0, 0)).blocks == [ordered("a", start: 5)])
    }

    @Test func pastedListItemsMoveToTheTargetIndent() {
        let result = paste("- x\n  - y", into: [bullet("p"), bullet("", indent: 1)], at: position(1, 0))
        #expect(result.blocks == [bullet("p"), bullet("x", indent: 1), bullet("y", indent: 2)])
    }

    @Test func aPasteReplacesTheSelection() {
        var target = editor([paragraph("ab")])
        target.select(selection(position(0, 0), position(0, 2)))
        target.paste(RichPasteContent(markdown: "x"))
        #expect(target.blocks == [paragraph("x")])
        #expect(target.selection == .caret(position(0, 1)))
    }

    @Test func plainTextIsReadAsMarkdownAndSplitIntoLines() {
        var target = editor([bullet("")])
        target.paste(RichPasteContent(plainText: "**a**\nb"))
        #expect(target.blocks == [.listItem(RichListItem(isOrdered: false), text: rich("a", (0..<1, .bold))), bullet("b")])
        var lines = editor([paragraph("a")], caret: position(0, 1))
        lines.paste(RichPasteContent(plainText: "line1\r\nline2"))
        #expect(lines.blocks == [paragraph("aline1"), paragraph("line2")])
    }

    @Test func theMarkdownTypeWins() {
        var target = editor([paragraph("")])
        target.paste(RichPasteContent(markdown: "**X**", plainText: "X"))
        #expect(target.blocks == [paragraph("X", (0..<1, .bold))])
    }

    @Test func intoCodeThePlainTextGoesInAsCode() {
        var target = editor([.codeBlock(language: nil, code: "")])
        target.paste(RichPasteContent(markdown: "## T", plainText: "## T"))
        #expect(target.blocks == [.codeBlock(language: nil, code: "## T")])
    }

    @Test func aPasteIsOneUndoStep() {
        var target = editor([paragraph("a")], caret: position(0, 1))
        target.paste(RichPasteContent(markdown: "b\n\n# c"))
        target.undo()
        #expect(target.blocks == [paragraph("a")])
        #expect(target.selection == .caret(position(0, 1)))
        target.redo()
        #expect(target.blocks == [paragraph("ab"), heading(1, "c")])
    }
}

/// Copy in rich mode, then paste: in rich mode the same block comes back, in source mode the text has the syntax.
@Suite("Copy then paste")
struct CopyPasteRoundTripTests {
    static let blocks: [RichBlock] = [
        heading(1, "One"), heading(6, "Six"), paragraph("all styles", (0..<3, .bold), (4..<6, .italic), (7..<8, .code), (8..<9, .underline), (9..<10, .strikethrough)),
        paragraph("link", (0..<4, link("https://mega.nz", title: "t"))), bullet("b"), ordered("o", start: 3), task("t", checked: true),
        quote("q", depth: 2), .codeBlock(language: "swift", code: "let a = 1\n")
    ]

    @Test(arguments: blocks)
    func aWholeBlockPastesBackTheSame(block: RichBlock) throws {
        var source = editor([block])
        source.selectAll()
        let content = try #require(source.copy())
        var target = editor([paragraph("")])
        target.paste(RichPasteContent(markdown: content.markdown, plainText: content.plainText))
        #expect(target.blocks == [block])
    }

    @Test func manyBlocksPasteBackTheSame() throws {
        var source = editor(Self.blocks)
        source.selectAll()
        let content = try #require(source.copy())
        var target = editor([paragraph("")])
        target.paste(RichPasteContent(markdown: content.markdown, plainText: content.plainText))
        #expect(target.blocks == Self.blocks)
    }

    /// Code has no Markdown syntax. A part of a code block pastes into a text block as the same characters.
    @Test(arguments: ["a*b*c", "<!-- x", "# not a heading", "[l](u)"])
    func aPartOfCodePastesAsTheSameText(part: String) throws {
        let source = editor([.codeBlock(language: nil, code: "x " + part + " y")])
        let range = selection(position(0, 2), position(0, 2 + part.utf16.count))
        let content = try #require(RichClipboard.content(of: source.document, in: range))
        #expect(content.plainText == part)
        var target = editor([paragraph("")])
        target.paste(RichPasteContent(markdown: content.markdown, plainText: content.plainText))
        #expect(target.blocks == [paragraph(part)])
    }

    /// A paragraph cannot keep indents or empty lines, so a code part of several lines pastes as one paragraph
    /// with its lines. The pasteboard still holds the raw code for source mode and other apps.
    @Test func aPartOfCodeOverLinesPastesAsItsTextLines() throws {
        let part = "    fetch()\n\n    render()"
        let source = editor([.codeBlock(language: nil, code: "func load() {\n" + part + "\n}")])
        let range = selection(position(0, 14), position(0, 14 + part.utf16.count))
        let content = try #require(RichClipboard.content(of: source.document, in: range))
        #expect(content.plainText == part)
        #expect(content.isCodePart)
        var target = editor([paragraph("")])
        target.paste(RichPasteContent(markdown: content.markdown, plainText: content.plainText))
        #expect(target.blocks == [paragraph("fetch()\nrender()")])
    }

    @Test func aPartKeepsItsSpacesAtTheEdges() throws {
        let source = editor([paragraph("hello world again")])
        let content = try #require(RichClipboard.content(of: source.document, in: selection(position(0, 6), position(0, 12))))
        var target = editor([paragraph("x")])
        target.paste(RichPasteContent(markdown: content.markdown, plainText: content.plainText))
        #expect(target.blocks == [paragraph("world x")])
        var bold = editor([paragraph("a b c", (2..<3, .bold))], caret: position(0, 5))
        let boldContent = try #require(RichClipboard.content(of: bold.document, in: selection(position(0, 1), position(0, 4))))
        bold.paste(RichPasteContent(markdown: boldContent.markdown, plainText: boldContent.plainText))
        #expect(bold.blocks == [paragraph("a b c b ", (2..<3, .bold), (6..<7, .bold))])
    }

    @Test func theMarkdownIsWhatSourceModePastes() throws {
        var source = editor([task("buy milk")])
        source.selectAll()
        let content = try #require(source.copy())
        #expect(content.markdown == "- [ ] buy milk")
    }

    @Test func cutIsOneUndoStep() {
        var target = editor([paragraph("abc"), paragraph("def")])
        target.select(selection(position(0, 1), position(1, 2)))
        let cut = target.cut()
        #expect(cut?.markdown == "bc\n\nde")
        #expect(target.blocks == [paragraph("af")])
        target.undo()
        #expect(target.blocks == [paragraph("abc"), paragraph("def")])
    }
}
