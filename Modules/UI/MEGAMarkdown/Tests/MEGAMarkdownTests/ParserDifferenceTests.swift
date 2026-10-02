import Foundation
@testable import MEGAMarkdown
import Testing

/// Places where the cmark parser differs from the old Foundation parser on purpose,
/// and inputs that crashed or froze the old parser.
@Suite struct ParserDifferenceTests {
    /// Foundation dropped the line break inside a link label over two lines ("FooBar"). cmark keeps it.
    @Test func linkLabelOverTwoLinesKeepsTheBreak() throws {
        let blocks = parse("[Foo\nBar]\n\n[foo bar]: https://a.example")
        #expect(blocks.first?.paragraphText == "Foo\nBar")
        let text = try #require(blocks.first.flatMap { block -> AttributedString? in
            if case .paragraph(let text) = block.kind { return text }
            return nil
        })
        #expect(text.runs.allSatisfy { $0.link == URL(string: "https://a.example") })
    }

    @Test func fiftyThousandNestedQuotesDoNotCrash() {
        let blocks = parse(String(repeating: ">", count: 50_000) + " deep")
        #expect(depth(of: blocks) == CmarkParser.maxNestingDepth)
        #expect(flatten(blocks).contains { $0.paragraphText == "deep" })
    }

    @Test func fiftyThousandNestedListsDoNotCrash() {
        let blocks = parse(String(repeating: "- ", count: 50_000) + "item")
        #expect(depth(of: blocks) <= CmarkParser.maxNestingDepth)
        #expect(depth(of: blocks) > 1)
        // cmark stops opening lists after 100 levels. The rest stays as text ("- - item").
        #expect(flatten(blocks).contains { $0.paragraphText?.hasSuffix("- item") == true })
    }

    @Test func mixedQuoteAndListNestingDoesNotCrash() {
        let blocks = parse(String(repeating: "> - ", count: 10_000) + "x")
        #expect(depth(of: blocks) <= CmarkParser.maxNestingDepth)
        #expect(depth(of: blocks) > 1)
        #expect(flatten(blocks).contains { $0.paragraphText?.hasSuffix("x") == true })
    }

    @Test func nestingUpToTheLimitIsKept() {
        let blocks = parse(String(repeating: ">", count: CmarkParser.maxNestingDepth) + " x")
        #expect(depth(of: blocks) == CmarkParser.maxNestingDepth)
    }

    /// Foundation took over 60 s for this. cmark is linear.
    @Test(.timeLimit(.minutes(1)))
    func wideTableParses() throws {
        let header = "|" + String(repeating: " h |", count: 5_000) + "\n"
        let delimiter = "|" + String(repeating: "---|", count: 5_000) + "\n"
        let row = "|" + String(repeating: " c |", count: 5_000) + "\n"
        let blocks = parse(header + delimiter + String(repeating: row, count: 200))
        let table = try #require(blocks.first?.table)
        #expect(table.columns.count == 5_000)
        #expect(table.rows.count == 200)
    }

    @Test(.timeLimit(.minutes(1)))
    func manyOpenBracketsParse() {
        let text = String(repeating: "[", count: 100_000)
        #expect(parse(text).count == 1)
        #expect(parse(text).first?.paragraphText == text)
    }

    @Test func thematicBreakHasItsRealLine() {
        let blocks = parse("Title\n---\n\npara\n\n***\n")
        #expect(blocks.map(\.sourceLine) == [0, 3, 5])
        #expect(blocks.last?.isThematicBreak == true)
    }

    /// cmark and Foundation give no line (Foundation: -1) to a paragraph cut short by a table.
    /// The new parser gives its real line. The table gets the same line from cmark.
    @Test(arguments: [
        ("# Head\n\nPara before table\n| x | y |\n|---|---|\n| 1 | 2 |\n", [0, 2, 2]),
        ("- a\n- b\n- c\n\nx\n| t |\n|---|\n| 1 |\n", [0, 4, 4]),
        ("> q\n\npara one\npara two\n| t |\n|---|\n", [0, 2, 2])
    ])
    func paragraphCutByTableGetsItsRealLine(markdown: String, lines: [Int]) {
        let blocks = parse(markdown)
        #expect(blocks.map(\.sourceLine) == lines)
    }

    /// Foundation keeps this item but gives the list line 0. The new parser gives the real line.
    @Test func listItemWithEmptyAltImageKeepsItsLine() throws {
        let blocks = parse("text\n\n- ![](u.png)\n")
        let list = try #require(blocks.last?.list)
        #expect(blocks.last?.sourceLine == 2)
        #expect(list.items.count == 1)
        #expect(list.items.first?.blocks.first?.image?.altText == "")
        #expect(list.items.first?.blocks.first?.image?.url == URL(string: "u.png"))
    }

    /// Foundation gives an image with no alt text the placeholder U+FFFC as alt text.
    /// The new parser gives "", so the renderer can treat the image as decoration.
    @Test func imageBlockWithoutAltTextHasEmptyAltText() throws {
        let blocks = parse("![](u.png)\n\n![alt](c.png)")
        #expect(blocks.count == 2)
        #expect(blocks.map { $0.image?.altText } == ["", "alt"])
        #expect(blocks.map { $0.image?.url } == [URL(string: "u.png"), URL(string: "c.png")])
        // Inside a paragraph the placeholder stays, like Foundation.
        #expect(parse("text ![](y.png) more").first?.paragraphText == "text \u{FFFC} more")
    }

    /// Foundation made one image block of two images with nothing between them and lost the second URL.
    @Test func twoAdjacentImagesKeepBothURLs() throws {
        let blocks = parse("![a](1.png)![b](2.png)")
        #expect(blocks.count == 1)
        #expect(blocks[0].image == nil)
        let text = try #require(blocks[0].paragraph)
        #expect(text.runs.compactMap(\.imageURL).map(\.absoluteString) == ["1.png", "2.png"])
        #expect(text.plain == "ab")
    }

    @Test func nulCharacterIsReplaced() {
        #expect(parse("a\u{0}b").first?.paragraphText == "a\u{FFFD}b")
    }

    private func depth(of blocks: [MarkdownBlock]) -> Int {
        // Iterative, so a wrong (very deep) result cannot crash the test itself.
        var maxDepth = 0
        var stack = blocks.map { ($0, 0) }
        while let (block, level) = stack.popLast() {
            let children = block.childBlocks
            let childLevel = level + (children.isEmpty ? 0 : 1)
            maxDepth = max(maxDepth, childLevel)
            stack += children.map { ($0, childLevel) }
        }
        return maxDepth
    }
}
