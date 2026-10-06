import Foundation
@testable import MEGAMarkdown
import Testing

@Suite struct ParsingNestingTests {
    @Test func bulletList() throws {
        let list = try #require(parse("- a\n- b\n- c").first?.list)
        #expect(list.isOrdered == false)
        #expect(list.startIndex == 1)
        #expect(list.items.map { $0.blocks.first?.paragraphText } == ["a", "b", "c"])
    }

    @Test func orderedListKeepsStartNumber() throws {
        // Quirk: `listItem` ordinal is the real number (3, 4), not an index.
        let list = try #require(parse("3. a\n4. b").first?.list)
        #expect(list.isOrdered)
        #expect(list.startIndex == 3)
        #expect(list.items.count == 2)
    }

    @Test func orderedListDefaultStart() throws {
        let list = try #require(parse("1. a\n2. b").first?.list)
        #expect(list.startIndex == 1)
    }

    @Test func threeLevelList() throws {
        let list = try #require(parse("- one\n  - two\n    - three\n- back").first?.list)
        #expect(list.items.count == 2)
        let level2 = try #require(list.items[0].blocks.last?.list)
        #expect(level2.items[0].blocks.first?.paragraphText == "two")
        let level3 = try #require(level2.items[0].blocks.last?.list)
        #expect(level3.items[0].blocks.first?.paragraphText == "three")
        #expect(list.items[1].blocks.first?.paragraphText == "back")
    }

    @Test func mixedOrderedInsideBullet() throws {
        let list = try #require(parse("- a\n  1. x\n  2. y").first?.list)
        let inner = try #require(list.items[0].blocks.last?.list)
        #expect(inner.isOrdered)
        #expect(inner.items.count == 2)
    }

    @Test func listInsideQuote() throws {
        let quote = try #require(parse("> intro\n> - li\n>   - nested").first?.quote)
        #expect(quote[0].paragraphText == "intro")
        let list = try #require(quote[1].list)
        #expect(list.items[0].blocks.first?.paragraphText == "li")
        #expect(list.items[0].blocks.last?.list?.items.first?.blocks.first?.paragraphText == "nested")
    }

    @Test func quoteInsideList() throws {
        let list = try #require(parse("- item\n  > quoted").first?.list)
        let blocks = list.items[0].blocks
        #expect(blocks[0].paragraphText == "item")
        #expect(blocks[1].quote?.first?.paragraphText == "quoted")
    }

    @Test func nestedQuotes() throws {
        let outer = try #require(parse("> a\n>> b").first?.quote)
        #expect(outer[0].paragraphText == "a")
        #expect(outer[1].quote?.first?.paragraphText == "b")
    }

    @Test func codeBlockInsideList() throws {
        let list = try #require(parse("- item\n\n  ```\n  code\n  ```").first?.list)
        #expect(list.items[0].blocks.last?.code?.code == "code")
    }

    @Test func looseListItemWithTwoParagraphs() throws {
        let list = try #require(parse("- first\n\n  second\n- next").first?.list)
        #expect(list.items[0].blocks.map(\.paragraphText) == ["first", "second"])
    }

    @Test func taskList() throws {
        let list = try #require(parse("- [ ] todo\n- [x] done\n- [X] Done too\n- plain\n- [ ]").first?.list)
        #expect(list.items.map(\.checkbox) == [.unchecked, .checked, .checked, nil, nil])
        #expect(list.items.map { $0.blocks.first?.paragraphText } == ["todo", "done", "Done too", "plain", "[ ]"])
    }

    /// `- [ ] ` is a valid task marker. cmark gives the item no content, but the checkbox must stay.
    @Test func emptyTaskItemKeepsItsCheckbox() throws {
        let list = try #require(parse("- [ ] \n- [x] a\n- [x] ").first?.list)
        #expect(list.items.map(\.checkbox) == [.unchecked, .checked, .checked])
        #expect(list.items.map { $0.blocks.first?.paragraphText } == ["", "a", ""])
        #expect(parse("-\n- a").first?.list?.items.count == 1)
    }

    /// cmark-gfm: the marker needs a space or tab after it on the same line. A line end is not enough.
    @Test(arguments: [MarkdownSoftBreak.lineBreak, .space])
    func taskMarkerAtLineEndIsText(mode: MarkdownSoftBreak) throws {
        let list = try #require(MarkdownParser.parse("- [ ]\n  next line\n- [x]\n  done", softBreak: mode).blocks.first?.list)
        #expect(list.items.map(\.checkbox) == [nil, nil])
        let separator = mode == .lineBreak ? "\n" : " "
        #expect(list.items.map { $0.blocks.first?.paragraphText } == ["[ ]\(separator)next line", "[x]\(separator)done"])
    }

    @Test func taskMarkerKeepsInlineStyle() throws {
        let list = try #require(parse("- [x] **bold** task").first?.list)
        guard case .paragraph(let text) = list.items[0].blocks[0].kind else {
            Issue.record("not a paragraph")
            return
        }
        #expect(text.plain == "bold task")
        #expect(text.runs.first?.inlinePresentationIntent == .stronglyEmphasized)
    }

    /// Only the leading marker sets the state. A later `[x]` on the line, as text, code or HTML, stays text.
    @Test(arguments: ["- [ ] Explain [x] syntax", "- [ ] Explain `[X]` syntax", "1. [ ] Explain [x] syntax", "- [ ] a <!-- [x] -->"])
    func laterMarkerDoesNotCheckTheTask(markdown: String) throws {
        let list = try #require(parse(markdown).first?.list)
        #expect(list.items.map(\.checkbox) == [.unchecked])
    }

    @Test func laterMarkerStaysInTheText() throws {
        #expect(parse("- [ ] Explain [x] syntax").first?.list?.items.first?.blocks.first?.paragraphText == "Explain [x] syntax")
        let item = try #require(parse("- [ ] Explain `[X]` syntax").first?.list?.items.first)
        let text = try #require(item.blocks.first?.paragraph)
        #expect(text.plain == "Explain [X] syntax")
        let code = try #require(text.range(of: "[X]"))
        #expect(text[code].runs.first?.inlinePresentationIntent == .code)
    }

    /// cmark's `tasklist` finds no marker after `>` or after a second list marker. The walker reads it from the source.
    @Test(arguments: [
        ("> - [x] done", MarkdownListItem.Checkbox.checked, "done"),
        ("> - [ ] todo", .unchecked, "todo"),
        ("- outer\n  > - [x] done", .checked, "done"),
        ("- - [x] done", .checked, "done"),
        ("1. - [X] done", .checked, "done"),
        ("> 1. [ ]\ttodo", .unchecked, "todo"),
        ("> - [ ] ", .unchecked, "")
    ])
    func taskInQuoteOrCompactListHasCheckbox(markdown: String, checkbox: MarkdownListItem.Checkbox, text: String) throws {
        let list = try #require(flatten(parse(markdown)).compactMap(\.list).last)
        #expect(list.items.map(\.checkbox) == [checkbox])
        #expect(list.items.first?.blocks.map(\.paragraphText) == [text])
    }

    @Test func taskInQuoteOrCompactListKeepsTheContainers() throws {
        let quote = try #require(parse("> - [x] done").first?.quote)
        #expect(quote.count == 1)
        #expect(quote.first?.list?.items.map(\.checkbox) == [.checked])
        let outer = try #require(parse("- outer\n  > - [x] done").first?.list)
        #expect(outer.items.map(\.checkbox) == [nil])
        #expect(outer.items.first?.blocks.first?.paragraphText == "outer")
        #expect(outer.items.first?.blocks.last?.quote?.first?.list?.items.map(\.checkbox) == [.checked])
        let compact = try #require(parse("- - [x] done").first?.list)
        #expect(compact.items.map(\.checkbox) == [nil])
        #expect(compact.items.first?.blocks.first?.list?.items.map(\.checkbox) == [.checked])
    }

    @Test func taskInQuoteKeepsInlineStyle() throws {
        let item = try #require(flatten(parse("> - [x] **bold** rest")).compactMap(\.list).last?.items.first)
        let text = try #require(item.blocks.first?.paragraph)
        #expect(item.checkbox == .checked)
        #expect(text.plain == "bold rest")
        #expect(text.runs.first?.inlinePresentationIntent == .stronglyEmphasized)
    }

    /// The same rules as a task at the line start: the marker must be plain source text with a space or tab after it.
    @Test(arguments: [
        ("> - \\[x] a", "[x] a"),
        ("> - &#91;x&#93; a", "[x] a"),
        ("> - **[x]** a", "[x] a"),
        ("> - [x]\n>   next", "[x]\nnext"),
        ("-\n  [x] a", "[x] a")
    ])
    func markerInQuoteThatIsNotATaskStaysText(markdown: String, text: String) throws {
        let list = try #require(flatten(parse(markdown)).compactMap(\.list).last)
        #expect(list.items.map(\.checkbox) == [nil])
        #expect(list.items.first?.blocks.first?.paragraphText == text)
    }

    /// Only the source spaces after the marker go. A space or tab from an entity is content, at the line start or not.
    @Test(arguments: [
        ("- [x] &#32;word", " word"), ("> - [x] &#32;word", " word"),
        ("- [x] &#9;word", "\tword"), ("> - [x] &#9;word", "\tword"),
        ("- - [x]  &#32;word", " word")
    ])
    func entityWhitespaceAfterTheMarkerStays(markdown: String, text: String) throws {
        let list = try #require(flatten(parse(markdown)).compactMap(\.list).last)
        #expect(list.items.map(\.checkbox) == [.checked])
        #expect(list.items.first?.blocks.first?.paragraphText == text)
    }

    /// With only spaces after the marker, the text starts on the next line. The break after the marker goes too.
    @Test(arguments: [
        "- [x] \n  next", "> - [x] \n>   next", "> - [x]  \n>   next", "- - [x] \n    next", "- [x]  \n  next"
    ])
    func taskTextOnTheNextLineHasNoLeadingBreak(markdown: String) throws {
        let list = try #require(flatten(parse(markdown)).compactMap(\.list).last)
        #expect(list.items.map(\.checkbox) == [.checked])
        #expect(list.items.first?.blocks.first?.paragraphText == "next")
    }

    @Test func bracketTextThatIsNotTaskStaysText() throws {
        let list = try #require(parse("- [link text] here\n- [y] no").first?.list)
        #expect(list.items.map(\.checkbox) == [nil, nil])
        #expect(list.items[1].blocks.first?.paragraphText == "[y] no")
    }

    @Test func idsAreUniqueAndDepthFirst() {
        let blocks = parse("# h\n\n- a\n  - b\n\n> q\n> - c\n\n| x |\n|---|\n| 1 |\n\n---\n\ntext")
        let ids = flatten(blocks).map(\.id)
        #expect(ids == Array(0..<ids.count))
    }

    @Test func sourceLinesAreZeroBased() {
        let markdown = "# Title\n\npara one\nstill one\n\n- item\n\n```\ncode\n```\n\n---\n\n> quote\n\n| a |\n|---|\n| 1 |"
        let blocks = parse(markdown)
        #expect(blocks.map(\.sourceLine) == [0, 2, 5, 7, 11, 13, 15])
        // Nested blocks carry their own line too.
        #expect(blocks[2].list?.items[0].blocks[0].sourceLine == 5)
    }

    @Test func thematicBreakLineIsFoundInsideQuote() {
        // Quirk: Foundation gives thematic breaks no source position; the parser scans the text.
        let blocks = parse("a\n\n> b\n>\n> ***\n\nc")
        #expect(blocks.map(\.sourceLine) == [0, 2, 6])
        let quote = blocks[1].quote ?? []
        #expect(quote.count == 2)
        #expect(quote[1].isThematicBreak)
        #expect(quote[1].sourceLine == 4)
    }
}
