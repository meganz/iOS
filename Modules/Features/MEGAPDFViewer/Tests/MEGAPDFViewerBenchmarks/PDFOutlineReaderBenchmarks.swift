import MEGABenchmark
@testable import MEGAPDFViewer
import XCTest

/// Measures loading and extracting the first outline walk from bundled PDFs.
/// Run with `scripts/benchmark.sh Modules/Features/MEGAPDFViewer`.
@MainActor
final class PDFOutlineReaderBenchmarks: BenchmarkCase {
    func testFlat100() throws { try benchmark(shape: "flat", count: 100) }
    func testFlat1000() throws { try benchmark(shape: "flat", count: 1_000) }
    func testFlat5000() throws { try benchmark(shape: "flat", count: 5_000) }
    func testFlat20000() throws { try benchmark(shape: "flat", count: 20_000) }

    func testBookLike100() throws {
        try benchmark(shape: "bookLike", count: 100)
    }

    func testBookLike1000() throws {
        try benchmark(shape: "bookLike", count: 1_000)
    }

    func testBookLike5000() throws {
        try benchmark(shape: "bookLike", count: 5_000)
    }

    func testBookLike20000() throws {
        try benchmark(shape: "bookLike", count: 20_000)
    }

    func testDeep100() throws { try benchmark(shape: "deep", count: 100) }
    func testDeep1000() throws { try benchmark(shape: "deep", count: 1_000) }
    func testDeep5000() throws { try benchmark(shape: "deep", count: 5_000) }
    func testDeep20000() throws { try benchmark(shape: "deep", count: 20_000) }

    private func benchmark(shape: String, count: Int) throws {
        let url = try XCTUnwrap(
            Bundle.module.url(
                forResource: "\(shape)-\(count)",
                withExtension: "pdf",
                subdirectory: "OutlineFixtures"
            )
        )
        let reader = PDFOutlineReader()
        measure(metrics: [
            XCTClockMetric(), XCTCPUMetric(), MainThreadStallMetric()
        ]) {
            let itemCount = try? runOnMainLoop {
                let items = await reader.outlineItems(
                    forDocumentAt: url,
                    documentLoader: PDFDocumentLoader()
                )
                return items.inOutlineOrder.count
            }
            XCTAssertEqual(itemCount, count)
        }
    }
}
