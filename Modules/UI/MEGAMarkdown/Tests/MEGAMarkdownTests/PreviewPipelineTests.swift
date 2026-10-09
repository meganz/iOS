import Foundation
@testable import MEGAMarkdown
import Testing

@Suite struct PreviewPipelineTests {
    private struct Result {
        var batches: [PreviewBatch]
        var outcome: PreviewPipeline.Outcome
        var rows: [PreviewRow] { batches.flatMap(\.rows) }
    }

    private static func parse(_ markdown: String, limits: PreviewParseLimits = PreviewParseLimits()) -> Result {
        var batches: [PreviewBatch] = []
        let outcome = PreviewPipeline.parse(MarkdownParseRequest(markdown: markdown), limits: limits) { batches.append($0) }
        return Result(batches: batches, outcome: outcome)
    }

    private static func limits(target: Int, maxChunkBytes: Int = MarkdownChunker.defaultMaxChunkBytes, weight: Int = 0) -> PreviewParseLimits {
        PreviewParseLimits(targetChunkBytes: target, maxChunkBytes: maxChunkBytes, maxRowWeight: weight)
    }

    /// One builder over the same chunks: the rows a single pass would give.
    private static func oneBuilderRows(_ markdown: String, limits: PreviewParseLimits) -> (rows: [PreviewRow], chunks: Int) {
        var source = markdown
        return source.withUTF8 { buffer in
            var chunker = MarkdownChunker(source: buffer, targetBytes: limits.targetChunkBytes, maxChunkBytes: limits.maxChunkBytes)
            var builder = PreviewRows.Builder(maxWeight: limits.maxRowWeight)
            var lastLine = 0
            var chunks = 0
            while let chunk = chunker.next() {
                chunks += 1
                let body = UnsafeBufferPointer(rebasing: buffer[chunk.bytes])
                if chunk.isPlainText {
                    builder.appendPlainText(String(decoding: body, as: UTF8.self), firstLine: chunk.lines.lowerBound)
                    continue
                }
                let parsed = CmarkParser.blocks(
                    prefix: chunker.definitionPrefix(for: chunk),
                    body: body,
                    softBreak: .lineBreak,
                    lineOffset: chunk.lines.lowerBound - chunker.definitionLineCount(for: chunk),
                    lastLine: lastLine
                )
                for block in parsed?.blocks ?? [] {
                    builder.append(block, decorations: [], gap: .block)
                }
                lastLine = parsed?.lastLine ?? lastLine
            }
            return (builder.rows, chunks)
        }
    }

    private static let paragraphs = (0..<200).map { "Paragraph \($0) with some words." }.joined(separator: "\n\n")

    // MARK: - Batches

    @Test func oneBatchPerChunkInSourceOrder() {
        let limits = Self.limits(target: 500)
        let result = Self.parse(Self.paragraphs, limits: limits)
        let reference = Self.oneBuilderRows(Self.paragraphs, limits: limits)
        #expect(result.outcome == .complete)
        #expect(reference.chunks == 13)
        #expect(result.batches.count == reference.chunks)
        #expect(result.batches.allSatisfy { !$0.rows.isEmpty })
        #expect(result.rows.map(\.sourceLine) == (0..<200).map { $0 * 2 })
    }

    @Test(arguments: [0, PreviewRows.maxRowWeight])
    func rowsMatchOneBuilderOverTheChunks(weight: Int) throws {
        let markdown = try ParserGoldenTests.fixture("c-mixed-100k.md")
        for target in [512, 4_096, 32_768] {
            let limits = Self.limits(target: target, weight: weight)
            let reference = Self.oneBuilderRows(markdown, limits: limits)
            let result = Self.parse(markdown, limits: limits)
            #expect(reference.chunks > 1, "target \(target)")
            #expect(result.batches.count == reference.chunks, "target \(target)")
            #expect(result.rows == reference.rows, "target \(target)")
        }
    }

    /// Long paragraphs with soft breaks are cut into pieces at newlines. The rows still equal one builder.
    @Test func paragraphPiecesMatchOneBuilderOverTheChunks() {
        let line = Array(repeating: "word", count: 12).joined(separator: " ")
        let paragraph = Array(repeating: line, count: 300).joined(separator: "\n")
        let markdown = Array(repeating: paragraph, count: 10).joined(separator: "\n\n")
        for target in [4_096, 32_768] {
            let limits = Self.limits(target: target)
            let reference = Self.oneBuilderRows(markdown, limits: limits)
            let result = Self.parse(markdown, limits: limits)
            #expect(reference.chunks > 1, "target \(target)")
            #expect(result.rows.count > 10, "target \(target)")
            #expect(result.rows == reference.rows, "target \(target)")
        }
    }

    /// The last row of a batch gets its gap below from the next chunk, like in one pass.
    @Test func gapBelowTheLastRowOfABatchComesFromTheNextChunk() {
        let result = Self.parse("First.\n\nSecond.\n\nThird.", limits: Self.limits(target: 1))
        #expect(result.batches.map { $0.rows.map(\.sourceLine) } == [[], [0], [2, 4]])
        #expect(result.rows.map(\.chrome.gapBelow) == [.block, .block, .none])
    }

    /// A definition in a later chunk is not known to an earlier chunk, so that reference stays literal text.
    @Test func lateLinkDefinitionStaysLiteral() throws {
        let markdown = "Early [a][r] and [b][s].\n\n[s]: /early-s\n\n" + Self.paragraphs + "\n\n[r]: /late\n\nLate [c][r].\n"
        let result = Self.parse(markdown, limits: Self.limits(target: 300))
        #expect(result.batches.count > 2)
        let texts = result.rows.compactMap { row -> InlineText? in
            if case .textPiece(let text, _, _) = row.content { return text }
            return nil
        }
        let early = try #require(texts.first)
        #expect(early.text == "Early [a][r] and b.")
        #expect(early.links.map(\.url) == ["/early-s"])
        let late = try #require(texts.last)
        #expect(late.text == "Late c.")
        #expect(late.links.map(\.url) == ["/late"])
    }

    // MARK: - Limits and notices

    @Test func emptyTextSendsOneEmptyBatch() {
        let result = Self.parse("")
        #expect(result.outcome == .complete)
        #expect(result.batches == [PreviewBatch(rows: [])])
    }

    @Test func textOverTheSizeLimitIsTooLarge() {
        var limits = PreviewParseLimits()
        limits.sizeLimitBytes = 10
        let over = Self.parse("12345678901", limits: limits)
        #expect(over.outcome == .tooLarge)
        #expect(over.batches.isEmpty)
        let atLimit = Self.parse("1234567890", limits: limits)
        #expect(atLimit.outcome == .complete)
        #expect(atLimit.rows.count == 1)
    }

    @Test func partOverTheChunkCapIsPlainTextAfterANotice() {
        let markdown = "# Title\n\n```\n" + String(repeating: "code line\n", count: 5_000) + "```\n"
        let result = Self.parse(markdown, limits: Self.limits(target: 1, maxChunkBytes: 10_000))
        #expect(result.outcome == .complete)
        let rows = result.rows
        guard case .textPiece(let title, headingLevel: 1, isFirst: true) = rows.first?.content else {
            Issue.record("first row \(String(describing: rows.first))")
            return
        }
        #expect(title.text == "Title")
        #expect(rows[1].content == .notice(.shownAsPlainText))
        #expect(rows[1].sourceLine == 2)
        let plain = rows.dropFirst(2).compactMap { row -> String? in
            if case .plainText(let text, _, _, _) = row.content { return text }
            return nil
        }
        #expect(plain.count == rows.count - 2)
        #expect(plain.joined(separator: "\n") == "```\n" + String(repeating: "code line\n", count: 5_000) + "```\n")
    }

    // MARK: - Cancellation and the stream

    /// The task is cancelled while the first batch is sent, so no other chunk is parsed.
    @Test func cancelStopsBeforeTheNextChunk() async {
        let result = await Task {
            var batches: [PreviewBatch] = []
            let request = MarkdownParseRequest(markdown: Self.paragraphs)
            let outcome = PreviewPipeline.parse(request, limits: Self.limits(target: 500)) { batch in
                batches.append(batch)
                withUnsafeCurrentTask { $0?.cancel() }
            }
            return Result(batches: batches, outcome: outcome)
        }.value
        #expect(result.outcome == .cancelled)
        #expect(result.batches.count == 1)
    }

    @Test func runSendsTheBatchesAndFinishesTheStream() async {
        let limits = Self.limits(target: 500)
        var batches: [PreviewBatch] = []
        do {
            for try await batch in PreviewPipeline.run(MarkdownParseRequest(markdown: Self.paragraphs), limits: limits) {
                batches.append(batch)
            }
        } catch {
            Issue.record("The stream threw \(error)")
        }
        #expect(batches == Self.parse(Self.paragraphs, limits: limits).batches)
    }

    @Test func runThrowsTooLargeForATextOverTheLimit() async {
        var limits = Self.limits(target: 500)
        limits.sizeLimitBytes = 10
        var batchCount = 0
        do {
            for try await _ in PreviewPipeline.run(MarkdownParseRequest(markdown: Self.paragraphs), limits: limits) {
                batchCount += 1
            }
            Issue.record("The stream ended without an error")
        } catch {
            #expect(error as? PreviewPipeline.Failure == .tooLarge)
        }
        #expect(batchCount == 0)
    }
}
