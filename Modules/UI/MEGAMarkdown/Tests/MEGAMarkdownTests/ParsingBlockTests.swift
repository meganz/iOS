import Foundation
@testable import MEGAMarkdown
import Testing

@Suite struct ParsingBlockTests {
    @Test func emptyInputGivesNoBlocks() {
        #expect(parse("").isEmpty)
        #expect(parse("\n\n   \n").isEmpty)
    }

    @Test(arguments: 1...6)
    func headingLevels(level: Int) throws {
        let blocks = parse(String(repeating: "#", count: level) + " Title **bold**")
        let heading = try #require(blocks.first?.heading)
        #expect(heading.level == level)
        #expect(heading.text == "Title bold")
    }

    @Test func setextHeading() throws {
        let heading = try #require(parse("Title\n=====").first?.heading)
        #expect(heading.level == 1)
        #expect(heading.text == "Title")
    }

    @Test func paragraphsAreSeparateBlocks() {
        let blocks = parse("one\n\ntwo")
        #expect(blocks.map(\.paragraphText) == ["one", "two"])
    }

    @Test func fencedCodeBlockKeepsLanguageAndDropsTrailingNewlines() throws {
        // Quirk: Foundation keeps the blank line before the closing fence as "\n\n".
        let code = try #require(parse("```swift\nlet a = 1\n  indented\n\n```").first?.code)
        #expect(code.language == "swift")
        #expect(code.code == "let a = 1\n  indented")
    }

    @Test func fencedCodeBlockWithoutLanguage() throws {
        let code = try #require(parse("```\nplain\n```").first?.code)
        #expect(code.language == nil)
        #expect(code.code == "plain")
    }

    @Test func indentedCodeBlock() throws {
        let code = try #require(parse("para\n\n    line1\n    line2\n").last?.code)
        #expect(code.language == nil)
        #expect(code.code == "line1\nline2")
    }

    /// cmark turns every line end into "\n". Views split code on "\n" only, so a cmark update must keep this.
    @Test(arguments: ["\r\n", "\r"])
    func codeBlockLineEndsAreNewlines(lineEnd: String) throws {
        let fenced = try #require(parse(["```swift", "a", "b", "```", ""].joined(separator: lineEnd)).first?.code)
        #expect(fenced.language == "swift")
        #expect(fenced.code == "a\nb")
        let indented = try #require(parse(["para", "", "    a", "    b", ""].joined(separator: lineEnd)).last?.code)
        #expect(indented.code == "a\nb")
    }

    @Test func codeBlockDoesNotParseMarkdownInside() throws {
        let code = try #require(parse("```\n# not heading\n**x**\n```").first?.code)
        #expect(code.code == "# not heading\n**x**")
    }

    @Test(arguments: ["---", "***", "___", "- - -"])
    func thematicBreak(marker: String) {
        let blocks = parse("above\n\n\(marker)\n\nbelow")
        #expect(blocks.count == 3)
        #expect(blocks[1].isThematicBreak)
    }

    @Test func standaloneImageBecomesImageBlock() throws {
        // Quirk: the image run holds the alt text (not U+FFFC) plus the `imageURL` attribute.
        let image = try #require(parse("![A *cat*](https://example.com/cat.png)").first?.image)
        #expect(image.url == URL(string: "https://example.com/cat.png"))
        #expect(image.altText == "A cat")
    }

    @Test func relativeImageUsesBaseURL() throws {
        let base = URL(string: "https://example.com/docs/")
        let blocks = MarkdownParser.parse("![logo](img/logo.png)", baseURL: base).blocks
        let image = try #require(blocks.first?.image)
        #expect(image.url?.absoluteString == "https://example.com/docs/img/logo.png")
    }

    @Test func imageInsideTextStaysParagraph() throws {
        let block = try #require(parse("see ![icon](i.png) here").first)
        #expect(block.paragraphText == "see icon here")
        guard case .paragraph(let text) = block.kind else { return }
        #expect(text.runs.contains { $0.imageURL != nil })
    }

    @Test func linkedImageStaysParagraph() throws {
        let block = try #require(parse("[![badge](b.png)](https://example.com)").first)
        #expect(block.image == nil)
        #expect(block.paragraphText == "badge")
    }

    /// The README badge pattern. The image URL is dropped, but the link must survive.
    @Test func linkedImageWithEmptyAltKeepsTheLink() throws {
        let only = try #require(parse("[![](b.png)](https://ci.example)").first?.paragraph)
        #expect(only.plain == "\u{FFFC}")
        #expect(only.runs.first?.link == URL(string: "https://ci.example"))
        let tail = try #require(parse("[![](b.png)](https://ci.example) tail").first?.paragraph)
        #expect(tail.plain == "\u{FFFC} tail")
        #expect(tail.runs.first?.link == URL(string: "https://ci.example"))
    }

    /// Nothing inside alt text adds a placeholder, not even an inner image with no alt text.
    @Test func imageNestedInAltTextIsDropped() throws {
        #expect(parse("![![](a.png)x](outer.png) and more").first?.paragraphText == "x and more")
        #expect(parse("![![](a.png)x](outer.png)").first?.image?.altText == "x")
        #expect(parse("![![](a.png)](outer.png)").first?.image?.altText == "")
    }

    @Test func htmlBlockIsKeptAsRawText() {
        // Quirk: an HTML block run has NO presentationIntent (only inline intent `blockHTML`).
        // Android drops HTML; we keep the raw text so no content disappears.
        let blocks = parse("<div>html</div>\n\npara <span>x</span>")
        #expect(blocks.count == 2)
        #expect(blocks[0].paragraphText == "<div>html</div>\n")
        // Quirk: inline HTML tags stay as literal text runs (inline intent `inlineHTML`).
        #expect(blocks[1].paragraphText == "para <span>x</span>")
    }

    @Test func blockQuoteHoldsChildBlocks() throws {
        let quote = try #require(parse("> # Title\n>\n> text").first?.quote)
        #expect(quote.count == 2)
        #expect(quote[0].heading?.text == "Title")
        #expect(quote[1].paragraphText == "text")
    }

    @Test func unicodeAndEmojiSurvive() throws {
        let blocks = parse("# Xin chào 👋🏽\n\n日本語 **đậm** 🇻🇳\n\n- 👨‍👩‍👧 family")
        try #require(blocks.count == 3)
        #expect(blocks[0].heading?.text == "Xin chào 👋🏽")
        #expect(blocks[1].paragraphText == "日本語 đậm 🇻🇳")
        #expect(blocks[2].list?.items.first?.blocks.first?.paragraphText == "👨‍👩‍👧 family")
    }

    @Test func allKindsInOneDocument() throws {
        let url = try #require(Bundle.module.url(forResource: "all-blocks", withExtension: "md", subdirectory: "Fixtures"))
        let blocks = parse(try String(contentsOf: url, encoding: .utf8))
        let kinds = flatten(blocks).map { block -> String in
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
        for kind in ["heading", "paragraph", "list", "code", "quote", "table", "break", "image"] {
            #expect(kinds.contains(kind), "missing \(kind)")
        }
        // Top level, in the order of the fixture: 6 headings, text, 3 lists, quote, 2 code blocks,
        // break, table, image, text with an inline image.
        let expected = Array(repeating: "heading", count: 6) + ["paragraph", "list", "list", "list", "quote", "code", "code",
                                                                  "break", "table", "image", "paragraph"]
        #expect(blocks.map(ParsingLargeInputTests.kindName) == expected)
        #expect(blocks.dropFirst(9).first?.list?.items.map(\.checkbox) == [.unchecked, .checked])
    }

    // MARK: - Thematic break lines

    @Test func thematicBreakLineAfterSetextHeading() {
        // The `---` under "Title" belongs to the heading. The real break is on line 3.
        let blocks = parse("Title\n---\n\n***")
        #expect(blocks.count == 2)
        #expect(blocks[0].heading?.level == 2)
        #expect(blocks.last?.isThematicBreak == true)
        #expect(blocks.last?.sourceLine == 3)
    }

    @Test func thematicBreakLineAfterMultiLineSetextHeading() {
        let blocks = parse("line a\nline b\n===\n\n---")
        #expect(blocks.count == 2)
        #expect(blocks.last?.sourceLine == 4)
    }

    @Test func thematicBreakRightAfterATXHeadingKeepsItsLine() {
        let blocks = parse("# Title\n---")
        #expect(blocks.count == 2)
        #expect(blocks.last?.isThematicBreak == true)
        #expect(blocks.last?.sourceLine == 1)
    }

    @Test func thematicBreakLineWithCRLF() {
        let blocks = parse("para\r\n\r\n---\r\n")
        #expect(blocks.last?.isThematicBreak == true)
        #expect(blocks.last?.sourceLine == 2)
    }

    // MARK: - HTML blocks

    @Test func separateHTMLBlocksStaySeparate() {
        let blocks = parse("<div>a</div>\n\n<div>b</div>")
        #expect(blocks.map(\.paragraphText) == ["<div>a</div>\n", "<div>b</div>\n"])
        #expect(blocks.map(\.sourceLine) == [0, 2])
    }

    @Test func multiLineHTMLBlockStaysOneBlock() {
        let blocks = parse("<u>\nraw block\nline3\n</u>\n\ntext")
        #expect(blocks.count == 2)
        #expect(blocks[0].paragraphText == "<u>\nraw block\nline3\n</u>\n")
        #expect(blocks[1].sourceLine == 5)
    }

    @Test func htmlBlockInsideListItemStaysInItem() throws {
        // Foundation gives this HTML run only the `listItem` intent, no paragraph. It is still a block of the item.
        let blocks = parse("- item\n\n  <div>x</div>\n")
        #expect(blocks.count == 1)
        let item = try #require(blocks.first?.list?.items.first)
        #expect(item.blocks.map(\.paragraphText) == ["item", "<div>x</div>\n"])
        #expect(item.blocks.last?.sourceLine == 2)
    }

    @Test func htmlBlockInsideQuoteStaysInQuote() throws {
        let quote = try #require(parse("> text\n>\n> <div>x</div>").first?.quote)
        #expect(quote.map(\.paragraphText) == ["text", "<div>x</div>\n"])
    }
}
