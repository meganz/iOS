import MEGABenchmark
@testable import MEGAMarkdown
import XCTest

/// Parser benchmarks with XCTest metrics. They run only with
/// `TEST_RUNNER_MEGA_BENCH=1`. Limits: `Limits.json` next to this file. Run: `scripts/benchmark.sh Modules/UI/MEGAMarkdown`.
final class ParsingBenchmarks: BenchmarkCase {
    private static let tenMegabytes = 10_000_000

    /// Two measured runs for the 10 MB parses: one takes seconds.
    private var heavyOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 2
        return options
    }

    /// Time, CPU and peak memory of a 2 MB parse.
    func testParseTwoMegabytes() {
        let markdown = BenchmarkDocuments.makeLargeDocument(targetBytes: 2_000_000)
        let expectedBlocks = Self.expectedBlocks(in: markdown)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            // The time only means something if the parse did the full work: 8 blocks per section.
            XCTAssertEqual(MarkdownParser.parse(markdown).blocks.count, expectedBlocks)
        }
    }

    /// The chunked parse of a 10 MB text: each chunk is parsed with its definitions prefix.
    func testChunkedParseTenMegabytes() {
        let markdown = BenchmarkDocuments.makeLargeDocument(targetBytes: Self.tenMegabytes)
        let expectedBlocks = Self.expectedBlocks(in: markdown)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()], options: heavyOptions) {
            let (blocks, chunks) = Self.chunkedParse(markdown)
            XCTAssertGreaterThan(chunks, 1)
            // The time only means something if every chunk parsed fully: 8 blocks per section, none lost at a cut.
            XCTAssertEqual(blocks.count, expectedBlocks)
        }
    }

    /// One whole parse of the same 10 MB text. Its peak memory is the number the chunked parse stays under.
    func testWholeParseTenMegabytes() {
        let markdown = BenchmarkDocuments.makeLargeDocument(targetBytes: Self.tenMegabytes)
        let expectedBlocks = Self.expectedBlocks(in: markdown)
        measure(metrics: [XCTClockMetric(), PeakFootprintMetric()], options: heavyOptions) {
            XCTAssertEqual(CmarkParser.blocks(markdown, softBreak: .lineBreak)?.count, expectedBlocks)
        }
    }

    /// The inputs from cmark's `pathological_tests.py`, parsed one after another. A case that turns quadratic
    /// takes seconds instead of milliseconds, so the sum shows it. `PathologicalInputTests` checks the output.
    func testPathologicalInputs() {
        let inputs = BenchmarkDocuments.pathologicalInputs()
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()], options: heavyOptions) {
            for input in inputs {
                XCTAssertEqual(MarkdownParser.parse(input.markdown).blocks.count, input.blocks, input.name)
            }
        }
    }

    /// Chunking frees each cmark tree before the next chunk. The whole parse holds one tree for all 10 MB.
    /// Chunked runs first, so heap that the first run frees helps the whole parse, not the chunked one.
    func testChunkedParseUsesLessMemoryThanWholeParse() throws {
        let markdown = BenchmarkDocuments.makeLargeDocument(targetBytes: Self.tenMegabytes)
        let chunked = try Self.peakGrowthMB { _ = Self.chunkedParse(markdown) }
        let whole = try Self.peakGrowthMB { _ = CmarkParser.blocks(markdown, softBreak: .lineBreak) }
        XCTAssertLessThan(chunked * 2, whole, "chunked \(chunked) MiB, whole \(whole) MiB")
        XCTAssertLessThan(chunked, 150, "chunked peak \(chunked) MiB")
    }

    /// Parse time must grow about linearly: 2x the input takes less than 3x the time. Uses the fastest of 3 runs.
    func testParseTimeGrowsLinearly() {
        let small = BenchmarkDocuments.makeLargeDocument(targetBytes: 500_000)
        let large = BenchmarkDocuments.makeLargeDocument(targetBytes: 1_000_000)
        var smallCount = 0
        var largeCount = 0
        let smallTime = Self.fastest { smallCount = MarkdownParser.parse(small).blocks.count }
        let largeTime = Self.fastest { largeCount = MarkdownParser.parse(large).blocks.count }
        XCTAssertLessThan(largeTime, smallTime * 3, "small \(smallTime), large \(largeTime)")
        // The times only mean something if both parses did the full work.
        XCTAssertGreaterThan(smallCount, 1_000)
        XCTAssertGreaterThanOrEqual(largeCount * 10, smallCount * 19, "small \(smallCount) blocks, large \(largeCount) blocks")
        XCTAssertGreaterThan(smallTime, .zero)
    }

    // MARK: - Helpers

    private static func expectedBlocks(in markdown: String) -> Int {
        (markdown.components(separatedBy: "## Section heading").count - 1) * 8
    }

    private static func chunkedParse(_ text: String) -> (blocks: [ParsedBlock], chunks: Int) {
        var markdown = text
        var blocks: [ParsedBlock] = []
        var chunks = 0
        markdown.withUTF8 { buffer in
            var chunker = MarkdownChunker(source: buffer)
            var lastLine = 0
            while let chunk = chunker.next() {
                chunks += 1
                let body = UnsafeBufferPointer(rebasing: buffer[chunk.bytes])
                let lineOffset = chunk.lines.lowerBound - chunker.definitionLineCount(for: chunk)
                let parsed = CmarkParser.blocks(
                    prefix: chunker.definitionPrefix(for: chunk), body: body, softBreak: .lineBreak, lineOffset: lineOffset, lastLine: lastLine
                )
                blocks += parsed?.blocks ?? []
                lastLine = parsed?.lastLine ?? lastLine
            }
        }
        return (blocks, chunks)
    }

    /// Peak heap growth in MiB while `work` runs, from the same sampler the metric uses.
    private static func peakGrowthMB(during work: () -> Void) throws -> Double {
        let metric = PeakFootprintMetric()
        metric.willBeginMeasuring()
        work()
        metric.didStopMeasuring()
        let measurements = try metric.reportMeasurements(from: .init(), to: .init())
        return try XCTUnwrap(measurements.first { $0.identifier == PeakFootprintMetric.identifier }).doubleValue
    }

    private static func fastest(_ work: () -> Void) -> Duration {
        (0..<3).map { _ in ContinuousClock().measure(work) }.min() ?? .zero
    }
}
