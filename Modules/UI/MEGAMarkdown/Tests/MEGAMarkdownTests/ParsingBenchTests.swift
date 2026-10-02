import Foundation
@testable import MEGAMarkdown
import os
import Testing

/// Timed benchmarks. They run only when the test environment has MARKDOWN_BENCH=1.
/// A busy CI machine would fail a time limit, so normal runs skip them.
/// Set it as an exported shell variable: `export TEST_RUNNER_MARKDOWN_BENCH=1`. As an xcodebuild argument it
/// does not reach the test runner, and this suite then skips without an error. Check the skipped count in the result.
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["MARKDOWN_BENCH"] == "1"))
struct ParsingBenchTests {
    @Test func parseTwoMegabytes() {
        let markdown = ParsingLargeInputTests.makeLargeDocument(targetBytes: 2_000_000)
        var blockCount = 0
        let duration = ContinuousClock().measure {
            blockCount = MarkdownParser.parse(markdown).blocks.count
        }
        print("BENCH parseTwoMegabytes ms=\(duration.milliseconds)")
        #expect(blockCount > 1_000)
        // The time only means something if the parse did the full work: 8 blocks per section.
        #expect(blockCount == (markdown.components(separatedBy: "## Section heading").count - 1) * 8)
        #expect(duration < .seconds(14), "took \(duration)")
    }

    /// The chunked parse of a 10 MB text, the way the preview does it: each chunk with its definitions prefix.
    @Test func chunkedParseTenMegabytes() {
        var markdown = ParsingLargeInputTests.makeLargeDocument(targetBytes: 10_000_000)
        let expectedBlocks = (markdown.components(separatedBy: "## Section heading").count - 1) * 8
        var blockCount = 0
        var chunkCount = 0
        let duration = ContinuousClock().measure {
            markdown.withUTF8 { buffer in
                var chunker = MarkdownChunker(source: buffer)
                var lastLine = 0
                while let chunk = chunker.next() {
                    chunkCount += 1
                    let body = UnsafeBufferPointer(rebasing: buffer[chunk.bytes])
                    let lineOffset = chunk.lines.lowerBound - chunker.definitionLineCount(for: chunk)
                    let parsed = CmarkParser.blocks(
                        prefix: chunker.definitionPrefix(for: chunk), body: body, softBreak: .lineBreak, lineOffset: lineOffset, lastLine: lastLine
                    )
                    blockCount += parsed?.blocks.count ?? 0
                    lastLine = parsed?.lastLine ?? lastLine
                }
            }
        }
        print("BENCH chunkedParseTenMegabytes ms=\(duration.milliseconds) chunks=\(chunkCount)")
        #expect(chunkCount > 1)
        // The time only means something if every chunk parsed fully: 8 blocks per section, none lost at a cut.
        #expect(blockCount == expectedBlocks)
        // Measured 3.7 s on an idle Mac. The limit only catches a big regression, like the 2 MB gate.
        #expect(duration < .seconds(40), "took \(duration)")
    }

    /// Peak memory of the chunked 10 MB parse against one whole parse of the same text, both to `ParsedBlock`s.
    /// Chunking frees each cmark tree before the next chunk. The whole parse holds one tree for all 10 MB.
    /// Chunked runs first, so any heap the first run frees helps the whole parse, not the chunked one.
    @Test(.timeLimit(.minutes(2)))
    func chunkedParseTenMegabytesPeakMemory() {
        var markdown = ParsingLargeInputTests.makeLargeDocument(targetBytes: 10_000_000)
        var chunkedBlocks: [ParsedBlock] = []
        let chunked = Self.peakFootprint {
            markdown.withUTF8 { buffer in
                var chunker = MarkdownChunker(source: buffer)
                var lastLine = 0
                while let chunk = chunker.next() {
                    let body = UnsafeBufferPointer(rebasing: buffer[chunk.bytes])
                    let lineOffset = chunk.lines.lowerBound - chunker.definitionLineCount(for: chunk)
                    let parsed = CmarkParser.blocks(
                        prefix: chunker.definitionPrefix(for: chunk), body: body, softBreak: .lineBreak, lineOffset: lineOffset, lastLine: lastLine
                    )
                    chunkedBlocks += parsed?.blocks ?? []
                    lastLine = parsed?.lastLine ?? lastLine
                }
            }
        }
        var wholeBlocks: [ParsedBlock] = []
        let whole = Self.peakFootprint { wholeBlocks = CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [] }
        print("BENCH chunkedParseTenMegabytesPeakMemory chunkedMB=\(chunked / 1_048_576) wholeMB=\(whole / 1_048_576)")
        #expect(chunkedBlocks.count == wholeBlocks.count)
        #expect(chunkedBlocks.count > 1_000)
        // Measured 36 MB against 366 MB on the simulator. Memory is steadier than time, so the margins are tighter.
        #expect(chunked * 2 < whole, "chunked \(chunked) B, whole \(whole) B")
        #expect(chunked < 150 * 1_048_576, "chunked peak \(chunked) B")
    }

    /// Parse time must grow about linearly: 2x the input takes less than 3x the time.
    /// Uses the fastest of 3 runs, so a busy machine does not fail it.
    @Test(.timeLimit(.minutes(2)))
    func parseTimeGrowsLinearly() {
        let small = ParsingLargeInputTests.makeLargeDocument(targetBytes: 500_000)
        let large = ParsingLargeInputTests.makeLargeDocument(targetBytes: 1_000_000)
        var smallCount = 0
        var largeCount = 0
        let smallTime = Self.fastest { smallCount = MarkdownParser.parse(small).blocks.count }
        let largeTime = Self.fastest { largeCount = MarkdownParser.parse(large).blocks.count }
        #expect(largeTime < smallTime * 3, "small \(smallTime), large \(largeTime)")
        // The times only mean something if both parses did the full work.
        #expect(smallCount > 1_000)
        #expect(largeCount * 10 >= smallCount * 19, "small \(smallCount) blocks, large \(largeCount) blocks")
        #expect(smallTime > .zero)
    }

    private static func fastest(_ work: () -> Void) -> Duration {
        (0..<3).map { _ in ContinuousClock().measure(work) }.min() ?? .zero
    }

    // MARK: - Memory

    /// Growth of the process footprint while `work` runs: the highest sample minus the footprint before.
    /// A background thread samples every millisecond, so a peak inside `work` is seen even if freed before it returns.
    private static func peakFootprint(during work: () -> Void) -> Int {
        let before = footprint()
        let state = OSAllocatedUnfairLock(initialState: (running: true, peak: before))
        let sampler = Thread {
            while state.withLock({ $0.running }) {
                let now = footprint()
                state.withLock { $0.peak = max($0.peak, now) }
                usleep(1_000)
            }
        }
        sampler.start()
        work()
        let after = footprint()
        state.withLock { $0.running = false }
        while !sampler.isFinished { usleep(1_000) }
        return max(state.withLock { $0.peak }, after) - before
    }

    /// `phys_footprint` is the number the Xcode memory gauge and the jetsam limit use.
    private static func footprint() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.phys_footprint) : 0
    }
}

private extension Duration {
    /// Milliseconds with 2 decimals, for the BENCH lines the script collects.
    var milliseconds: String {
        let value = Double(components.seconds) * 1_000 + Double(components.attoseconds) / 1e15
        return String(format: "%.2f", value)
    }
}
