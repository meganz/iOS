import Foundation
@testable import MEGAMarkdown
import Testing

/// Edge cases of rebuilt definitions in chunks and of the tree walker. Each test pins the exact output.
@Suite struct ParserEdgeCaseTests {
    // MARK: - Chunker: rebuilt definitions

    /// Whole parse and production chunking (prefix known when each chunk is produced) give the same tree.
    private static func sameTrees(_ text: String, target: Int, maxChunkBytes: Int = MarkdownChunker.defaultMaxChunkBytes) -> String? {
        var source = text
        let whole = ChunkedParseTests.whole(text)
        let chunked: [String] = source.withUTF8 { buffer in
            var chunker = MarkdownChunker(source: buffer, targetBytes: target, maxChunkBytes: maxChunkBytes)
            var trees: [String] = []
            while let chunk = chunker.next() {
                if chunk.isPlainText { trees.append("PLAINTEXT lines=\(chunk.lines)"); continue }
                trees += CmarkParser.debugTree(
                    prefix: chunker.definitionPrefix(for: chunk),
                    body: UnsafeBufferPointer(rebasing: buffer[chunk.bytes]),
                    lineOffset: chunk.lines.lowerBound - chunker.definitionLineCount(for: chunk)
                )
            }
            return trees
        }
        return ChunkedParseTests.firstDifference(whole, chunked)
    }

    @Test func entityInARebuiltURLIsDecodedOnce() throws {
        let text = "[x]: </a&amp;amp;b>\n\nsee [y][x]\n"
        #expect(Self.sameTrees(text, target: 1) == nil)
        let blocks = parse(text)
        #expect(blocks.count == 1)
        let attributed = try #require(blocks.first?.paragraph)
        #expect(attributed.runs.compactMap(\.link).map(\.absoluteString) == ["/a&amp;b"])
    }

    @Test func entityInARebuiltTitleIsDecodedOnce() {
        #expect(Self.sameTrees("[x]: /u \"a &amp;amp; b\"\n\nsee [y][x]\n", target: 1) == nil)
    }

    @Test func combiningMarkAfterAnEscapedBracketKeepsTheDefinition() {
        #expect(Self.sameTrees("[x]: </a\\<\u{301}b>\n\nsee [y][x]\n", target: 1) == nil)
        #expect(Self.sameTrees("[x]: /u \"a\\\"\u{301}b\"\n\nsee [y][x]\n", target: 1) == nil)
    }

    @Test func escapedPunctuationInATwoLineTitleStaysATitle() {
        #expect(Self.sameTrees("[a]: /u \"see\n\\# note\"\n\nx\n\n[use][a]\n", target: 1) == nil)
    }

    @Test func byteOrderMarkAtAChunkStartIsKept() {
        #expect(Self.sameTrees("a\n\n\u{FEFF}b\n", target: 1) == nil)
        #expect(Self.sameTrees("a\n\n\u{FEFF}\n", target: 1) == nil)
        // A byte order mark at the file start is still dropped, like cmark does.
        #expect(Self.sameTrees("\u{FEFF}# T\n\ntext\n", target: 1) == nil)
        #expect(parse("\u{FEFF}# T").first?.heading?.text == "T")
    }

    @Test(arguments: ["\u{A0}", "\u{3000}"])
    func labelOfUnicodeSpaceIsShared(label: String) {
        #expect(Self.sameTrees("[\(label)]: /nb\n\nsee [x][\(label)]\n", target: 1) == nil)
    }

    /// cmark decodes `&#10;` and `&#13;` in a URL or title. The rebuilt definition must encode them again,
    /// or the raw line break ends the definition line.
    @Test(arguments: [
        "[x]: /target \"a&#10;&#10;b\"\n\n[visible][x]\n",
        "[x]: </a&#10;b>\n\n[visible][x]\n",
        "[x]: /target \"a&#13;b\"\n\n[visible][x]\n"
    ])
    func encodedLineBreakInARebuiltDefinitionStaysOneLine(text: String) {
        #expect(Self.sameTrees(text, target: 1) == nil)
    }

    /// cmark compares labels as bytes, so `\u{E9}` and `e\u{301}` are two labels with two definitions.
    /// Swift `String` equality treats them as one.
    @Test func composedAndDecomposedLabelsAreTwoDefinitions() throws {
        let text = "[\u{E9}]: /composed\n\n[e\u{301}]: /decomposed\n\n[a][\u{E9}] [b][e\u{301}]\n"
        #expect(Self.sameTrees(text, target: 1) == nil)
        let links = try #require(parse(text).last?.paragraph).runs.compactMap(\.link).map(\.absoluteString)
        #expect(links == ["/composed", "/decomposed"])
    }

    @Test func unsafeCutNearTheCapStillFindsTheSafeCutUnderIt() {
        // The fence closes at byte 57 and a safe cut follows at byte 59. The first candidate (byte 52) is inside the fence.
        let text = "```\n" + String(repeating: "a\n\nb\n", count: 10) + "```\n\nX\n\n" + String(repeating: "Y\n\n", count: 30)
        #expect(Self.sameTrees(text, target: 50, maxChunkBytes: 100) == nil)
        var source = text
        let chunks: [MarkdownChunker.Chunk] = source.withUTF8 { buffer in
            var chunker = MarkdownChunker(source: buffer, targetBytes: 50, maxChunkBytes: 100)
            var result: [MarkdownChunker.Chunk] = []
            while let chunk = chunker.next() { result.append(chunk) }
            return result
        }
        #expect(chunks.allSatisfy { !$0.isPlainText })
        #expect(chunks.first?.bytes == 0..<59)
    }

    /// The walker reads task markers from the source bytes. A later chunk starts with the definition prefix,
    /// so the marker offset must count the prefix lines too.
    @Test func taskMarkerInALaterChunkIsReadAfterTheDefinitionPrefix() throws {
        let text = "[d]: /u\n\nfirst [d]\n\n> - [ ] todo [x]\n\n- [x] done\n\n- - [x] inner\n"
        var source = text
        let chunked: [MarkdownBlock] = try source.withUTF8 { buffer in
            var chunker = MarkdownChunker(source: buffer, targetBytes: 1)
            var nextID = 0
            var lastLine = 0
            var blocks: [MarkdownBlock] = []
            while let chunk = chunker.next() {
                let result = try #require(CmarkParser.blocks(
                    prefix: chunker.definitionPrefix(for: chunk),
                    body: UnsafeBufferPointer(rebasing: buffer[chunk.bytes]),
                    softBreak: .lineBreak,
                    lineOffset: chunk.lines.lowerBound - chunker.definitionLineCount(for: chunk),
                    lastLine: lastLine
                ))
                lastLine = result.lastLine
                blocks += result.blocks.map { $0.markdownBlock(nextID: &nextID, baseURL: nil) }
            }
            return blocks
        }
        #expect(chunked == parse(text))
        #expect(flatten(chunked).compactMap(\.list).flatMap { $0.items.map(\.checkbox) } == [.unchecked, .checked, nil, .checked])
    }

    // MARK: - Walker

    // Two adjacent images: see ParserDifferenceTests.twoAdjacentImagesKeepBothURLs (a wanted difference).

    @Test func singleImageIsStillAnImageBlock() throws {
        let image = try #require(parse("![a](1.png)").first?.image)
        #expect(image.url?.absoluteString == "1.png")
        #expect(image.altText == "a")
    }

    @Test func linkWithEmptyTextKeepsTheLink() throws {
        let text = try #require(parse("[](http://a) tail").first?.paragraph)
        #expect(text.plain == "\u{FFFC} tail")
        #expect(text.runs.compactMap(\.link).map(\.absoluteString) == ["http://a"])
        let alone = try #require(parse("[](http://a)").first?.paragraph)
        #expect(alone.plain == "\u{FFFC}")
        #expect(alone.runs.compactMap(\.link).map(\.absoluteString) == ["http://a"])
    }

    @Test(arguments: [
        ("- **[x]** bold", "[x] bold"),
        ("- `[ ]` code", "[ ] code"),
        ("- [[x]](http://a) link", "[x] link"),
        ("- <b>[x]</b> html", "[x] html")
    ])
    func taskMarkerInsideStyledTextIsNotATask(markdown: String, plain: String) throws {
        let list = try #require(parse(markdown).first?.list)
        #expect(list.items.count == 1)
        #expect(list.items[0].checkbox == nil)
        #expect(list.items[0].blocks.first?.paragraphText == plain)
    }

    @Test func styledTextAfterAPlainMarkerIsStillATask() throws {
        let list = try #require(parse("- [x] **bold** rest").first?.list)
        #expect(list.items[0].checkbox == .checked)
        #expect(list.items[0].blocks.first?.paragraphText == "bold rest")
    }

    @Test func tabAfterTheTaskMarkerIsATask() throws {
        let list = try #require(parse("- [x]\tafter tab").first?.list)
        #expect(list.items[0].checkbox == .checked)
        #expect(list.items[0].blocks.first?.paragraphText == "after tab")
    }

    @Test func styleTagsDoNotPairAcrossALinkBoundary() throws {
        let crossing = try #require(parse("[<u>](x)</u>").first?.paragraph)
        #expect(crossing.plain == "<u></u>")
        #expect(crossing.runs.compactMap(\.link).map(\.absoluteString) == ["x"])
        #expect(crossing.runs.allSatisfy { $0[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == nil })
        let open = try #require(parse("[<u>a](x)</u>").first?.paragraph)
        #expect(open.plain == "<u>a</u>")
        let inside = try #require(parse("[<u>a</u>](x)").first?.paragraph)
        #expect(inside.plain == "a")
        #expect(inside.runs.first?[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == .single)
    }

    @Test func emptyTagPairStaysLiteral() throws {
        let blocks = parse("# <u></u>\n\ntext")
        #expect(blocks.count == 2)
        #expect(blocks[0].heading?.text == "<u></u>")
        #expect(parse("<u></u>").first?.paragraphText == "<u></u>")
        let list = try #require(parse("1. <u></u>\n2. b").first?.list)
        #expect(list.startIndex == 1)
        #expect(list.items.map { $0.blocks.first?.paragraphText } == ["<u></u>", "b"])
        // A pair with content between the tags still styles it.
        #expect(parse("<u>x</u>").first?.paragraphText == "x")
    }

    @Test func imageWithEmptyURLIsPlainText() throws {
        let blocks = parse("![a]()")
        #expect(blocks.first?.image == nil)
        #expect(blocks.first?.paragraphText == "a")
    }

    @Test func taskItemWithOnlyAnImageIsAnImageBlock() throws {
        let list = try #require(parse("- [x] ![alt](u.png)").first?.list)
        #expect(list.items[0].checkbox == .checked)
        let image = try #require(list.items[0].blocks.first?.image)
        #expect(image.url?.absoluteString == "u.png")
        #expect(image.altText == "alt")
    }

    @Test func authorTypedObjectReplacementCharacterStaysInAltText() throws {
        let image = try #require(parse("![\u{FFFC}x](u)").first?.image)
        #expect(image.altText == "\u{FFFC}x")
        // The placeholder the parser adds for an empty alt text still does not reach the model.
        #expect(parse("![](u)").first?.image?.altText == "")
    }
}
