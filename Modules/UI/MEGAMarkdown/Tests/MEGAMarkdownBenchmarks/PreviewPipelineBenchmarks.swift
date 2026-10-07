import MEGABenchmark
@testable import MEGAMarkdown
import XCTest

/// The preview parse of a 10 MB document: the first batch, and all rows.
/// Run: `scripts/benchmark.sh ... --only PreviewPipelineBenchmarks`.
@MainActor
final class PreviewPipelineBenchmarks: BenchmarkCase {
    private static let tenMegabytes = 10_000_000
    private static var cachedMarkdown: String?

    private var markdown: String {
        if let cachedMarkdown = Self.cachedMarkdown { return cachedMarkdown }
        let markdown = BenchmarkDocuments.makeLargeDocument(targetBytes: Self.tenMegabytes)
        Self.cachedMarkdown = markdown
        return markdown
    }

    private var heavyOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        return options
    }

    /// From the start of the parse to the first batch. The parse stops there, as when the view goes away.
    func testFirstBatchTenMegabytes() throws {
        let request = MarkdownParseRequest(markdown: markdown)
        measure(metrics: [XCTClockMetric(), PeakFootprintMetric()], options: heavyOptions) {
            let rows = try? runOnMainLoop {
                await Self.firstBatchRowCount(request)
            }
            XCTAssertGreaterThan(rows ?? 0, 1_000)
        }
    }

    /// Off the main actor, like the preview. It stops after the first batch.
    @concurrent
    private static func firstBatchRowCount(_ request: MarkdownParseRequest) async -> Int {
        var rows = 0
        _ = PreviewPipeline.parse(request, limits: PreviewParseLimits()) { batch in
            rows = batch.rows.count
            withUnsafeCurrentTask { $0?.cancel() }
        }
        return rows
    }

    /// Every chunk, on the test thread. The rows are counted, not kept, so the peak is the parse itself.
    func testFullParseTenMegabytes() {
        let request = MarkdownParseRequest(markdown: markdown)
        measure(metrics: [XCTClockMetric(), PeakFootprintMetric()], options: heavyOptions) {
            var rows = 0
            var batches = 0
            let outcome = PreviewPipeline.parse(request, limits: PreviewParseLimits()) { batch in
                rows += batch.rows.count
                batches += 1
            }
            XCTAssertEqual(outcome, .complete)
            XCTAssertGreaterThan(batches, 5)
            XCTAssertGreaterThan(rows, 100_000)
        }
    }
}
