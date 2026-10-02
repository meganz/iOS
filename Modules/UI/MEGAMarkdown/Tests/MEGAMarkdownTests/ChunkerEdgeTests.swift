import Foundation
@testable import MEGAMarkdown
import Testing

/// Chunker inputs that the fuzz and the fixtures never make: they always end with a newline.
@Suite struct ChunkerEdgeTests {
    @Test func emptyTextMatchesWholeParse() {
        let result = ChunkedParseTests.chunked("", target: 1)
        let difference = ChunkedParseTests.firstDifference(ChunkedParseTests.whole(""), result.trees)
        #expect(difference == nil, "\(difference ?? "")")
        // Two empty trees are always equal, so also check that nothing was made.
        #expect(ChunkedParseTests.whole("").isEmpty)
        #expect(result.trees.isEmpty)
        #expect(result.chunks.count <= 1)
        #expect(result.chunks.allSatisfy { $0.bytes.isEmpty })
    }

    @Test func lastLineWithoutNewlineIsInTheLastChunk() throws {
        let text = "# A\n\nlast line"
        let whole = ChunkedParseTests.whole(text)
        try #require(whole.count == 2, "heading and paragraph: \(whole)")
        for target in [1, 4] {
            let result = ChunkedParseTests.chunked(text, target: target)
            let difference = ChunkedParseTests.firstDifference(whole, result.trees)
            #expect(difference == nil, "target \(target): \(difference ?? "")")
            #expect(result.chunks.last?.bytes.upperBound == text.utf8.count, "target \(target)")
        }
        // A small target must really cut, so the last line is in a chunk of its own.
        #expect(ChunkedParseTests.chunked(text, target: 1).chunks.count > 1)
    }

    // MARK: - QA additions

    @Test(arguments: ["\n\n   \n", "\r\n\r\n", "\r\r", "   "])
    func whitespaceOnlyTextGivesNoBlocks(text: String) {
        let result = ChunkedParseTests.chunked(text, target: 1)
        #expect(ChunkedParseTests.whole(text).isEmpty)
        #expect(result.trees.isEmpty, "\(text.debugDescription): \(result.trees)")
        #expect((result.chunks.last?.bytes.upperBound ?? 0) == text.utf8.count, "\(text.debugDescription)")
    }

    @Test(arguments: ["# A\r\n\r\nlast line", "# A\r\rlast line"])
    func lastLineWithoutNewlineAfterCRLineEndsIsInTheLastChunk(text: String) {
        let whole = ChunkedParseTests.whole(text)
        #expect(whole.count == 2, "\(whole)")
        for target in [1, 4] {
            let result = ChunkedParseTests.chunked(text, target: target)
            let difference = ChunkedParseTests.firstDifference(whole, result.trees)
            #expect(difference == nil, "\(text.debugDescription) target \(target): \(difference ?? "")")
            #expect(result.chunks.last?.bytes.upperBound == text.utf8.count, "\(text.debugDescription) target \(target)")
        }
    }

    /// Chunks must follow each other with no gap and no overlap, so no text is lost or shown twice.
    @Test(arguments: [1, 64, 4_096])
    func chunksCoverTheWholeTextInOrder(target: Int) throws {
        let text = ParsingLargeInputTests.makeLargeDocument(targetBytes: 20_000) + "tail line without newline"
        let result = ChunkedParseTests.chunked(text, target: target)
        let first = try #require(result.chunks.first)
        #expect(first.bytes.lowerBound == 0)
        #expect(first.lines.lowerBound == 0)
        for (previous, next) in zip(result.chunks, result.chunks.dropFirst()) {
            #expect(next.bytes.lowerBound == previous.bytes.upperBound, "\(previous) -> \(next)")
            #expect(next.lines.lowerBound == previous.lines.upperBound, "\(previous) -> \(next)")
        }
        #expect(result.chunks.last?.bytes.upperBound == text.utf8.count)
        #expect(result.chunks.last?.lines.upperBound == text.split(separator: "\n", omittingEmptySubsequences: false).count)
        #expect(result.chunks.count > 1)
        #expect(ChunkedParseTests.firstDifference(ChunkedParseTests.whole(text), result.trees) == nil)
    }

    /// A cut must never split a multi-byte character, so every chunk is valid UTF-8 on its own.
    @Test func multiByteTextCutsOnCharacterBoundaries() {
        let text = "# Xin chào 👋🏽\n\n日本語 **đậm** 🇻🇳\n\n- 👨‍👩‍👧 family\n\nlast 😀"
        let bytes = Array(text.utf8)
        for target in [1, 3, 7] {
            let result = ChunkedParseTests.chunked(text, target: target)
            #expect(result.chunks.count > 1, "target \(target)")
            for chunk in result.chunks {
                let piece = String(bytes: bytes[chunk.bytes], encoding: .utf8)
                #expect(piece != nil, "target \(target): \(chunk)")
            }
            let difference = ChunkedParseTests.firstDifference(ChunkedParseTests.whole(text), result.trees)
            #expect(difference == nil, "target \(target): \(difference ?? "")")
        }
    }

    /// A UTF-8 byte order mark is 3 bytes before the first line. The chunker skips them, so the first chunk
    /// starts at byte 3 and the first line is still line 0. cmark drops the mark itself only at the very start.
    @Test func byteOrderMarkIsSkipped() throws {
        let text = "\u{FEFF}# A\n\n- item\n\nlast"
        let whole = ChunkedParseTests.whole(text)
        try #require(whole.count == 3, "heading, list and paragraph: \(whole)")
        for target in [1, 8] {
            let result = ChunkedParseTests.chunked(text, target: target)
            #expect(result.chunks.count > 1, "target \(target)")
            #expect(result.chunks.first?.bytes.lowerBound == 3, "target \(target)")
            #expect(result.chunks.first?.lines.lowerBound == 0, "target \(target)")
            let difference = ChunkedParseTests.firstDifference(whole, result.trees)
            #expect(difference == nil, "target \(target): \(difference ?? "")")
        }
    }

    /// The link definition comes after the cut. The earlier chunk must still show the link.
    /// cmark gives the title decoded, so every ASCII punctuation is escaped again when the definition is rebuilt.
    @Test(arguments: ["\\# note", "&#35; note", "\\> note", "\\- x", "\\``` x", "1\\. x", "---", "note"])
    func definitionTitleOverTwoLinesMatchesWholeParse(secondLine: String) {
        let text = "[a]: /u \"see\n\(secondLine)\"\n\nx\n\n[use][a]"
        let result = ChunkedParseTests.chunked(text, target: 1)
        #expect(result.chunks.count > 1)
        let difference = ChunkedParseTests.firstDifference(ChunkedParseTests.whole(text), result.trees)
        #expect(difference == nil, "\(difference ?? "")")
    }

    @Test func referenceLinkDefinedAfterTheCutMatchesWholeParse() throws {
        let text = "[see][late]\n\nmiddle paragraph\n\n[late]: https://mega.io \"Title\"\n"
        let paragraph = try #require(parse(text).first)
        guard case .paragraph(let attributed) = paragraph.kind else {
            Issue.record("not a paragraph: \(paragraph.kind)")
            return
        }
        #expect(attributed.runs.first?.link == URL(string: "https://mega.io"))
        for target in [1, 4] {
            let result = ChunkedParseTests.chunked(text, target: target)
            #expect(result.chunks.count > 1, "target \(target)")
            let difference = ChunkedParseTests.firstDifference(ChunkedParseTests.whole(text), result.trees)
            #expect(difference == nil, "target \(target): \(difference ?? "")")
        }
    }
}
