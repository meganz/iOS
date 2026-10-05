import MEGABenchmark
@testable import MEGAPDFViewer
import PDFKit
import XCTest

/// `PDFThumbnailLoader` benchmarks with XCTest metrics. They run only with
/// `TEST_RUNNER_MEGA_BENCH=1`. Limits: `Limits.json` next to this file.
/// Run: `scripts/benchmark.sh Modules/Features/MEGAPDFViewer`.
@MainActor
final class PDFThumbnailLoaderBenchmarks: BenchmarkCase {
    /// One portrait screenful of scanned pages, requested at once the way the
    /// grid does, from a newly opened document and an empty cache.
    func testRenderScreenfulOfScannedPages() throws {
        let url = try BenchmarkDocuments.makeScannedDocument()
        let pages = 0..<ThumbnailGeometry.portraitScreenful
        // No wall-clock metric, see `testConcurrentRendersOfDistinctPages` in
        // `PDFPageConcurrentRenderBenchmarks`.
        measure(metrics: [XCTCPUMetric(), MainThreadStallMetric(), PeakFootprintMetric()]) {
            let rendered = try? runOnMainLoop {
                await Self.loadThumbnails(url: url, pages: pages, cell: ThumbnailGeometry.portraitCell).count
            }
            XCTAssertEqual(rendered, pages.count)
        }
    }

    /// The same screenful of text pages, the cheap end of the range.
    func testRenderScreenfulOfTextPages() throws {
        let url = try BenchmarkDocuments.makeTextDocument()
        let pages = 0..<ThumbnailGeometry.portraitScreenful
        // No wall-clock metric, see `testConcurrentRendersOfDistinctPages` in
        // `PDFPageConcurrentRenderBenchmarks`.
        measure(metrics: [XCTCPUMetric(), MainThreadStallMetric()]) {
            let rendered = try? runOnMainLoop {
                await Self.loadThumbnails(url: url, pages: pages, cell: ThumbnailGeometry.portraitCell).count
            }
            XCTAssertEqual(rendered, pages.count)
        }
    }

    /// The legacy viewer's approach for the same screenful: one render after
    /// another on the main thread. The stall it shows is what the loader's
    /// background renders avoid.
    func testRenderScreenfulOfScannedPagesOnMainThread() throws {
        let url = try BenchmarkDocuments.makeScannedDocument()
        let pages = 0..<ThumbnailGeometry.portraitScreenful
        let pixelSize = ThumbnailGeometry.pixelSize(of: ThumbnailGeometry.portraitCell)
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric()]) {
            let rendered = try? runOnMainLoop {
                guard let document = PDFDocument(url: url) else { return 0 }
                return pages.compactMap { document.page(at: $0)?.thumbnail(of: pixelSize, for: .cropBox) }.count
            }
            XCTAssertEqual(rendered, pages.count)
        }
    }

    /// Three landscape screenfuls, the most the cache must hold. The loader
    /// keeps every thumbnail, so the heap growth is the cache's size.
    func testRenderThreeLandscapeScreenfuls() throws {
        let url = try BenchmarkDocuments.makeScannedDocument()
        let pages = 0..<(ThumbnailGeometry.landscapeScreenful * 3)
        // No wall-clock metric, see `testConcurrentRendersOfDistinctPages` in
        // `PDFPageConcurrentRenderBenchmarks`.
        measure(metrics: [PeakFootprintMetric()]) {
            let decodedBytes = try? runOnMainLoop {
                await Self.loadThumbnails(url: url, pages: pages, cell: ThumbnailGeometry.landscapeCell)
            }
            XCTAssertEqual(decodedBytes?.count, pages.count)
            // The cache budget of `PDFThumbnailLoader`.
            XCTAssertLessThanOrEqual(decodedBytes?.reduce(0, +) ?? .max, 120 * 1_024 * 1_024)
        }
    }

    // MARK: - Helpers

    /// The decoded byte count of each thumbnail the loader returned.
    private static func loadThumbnails(url: URL, pages: Range<Int>, cell: CGSize) async -> [Int] {
        guard let document = PDFDocument(url: url) else { return [] }
        let loader = PDFThumbnailLoader(document: document)
        return await withTaskGroup(of: Int?.self) { group in
            for page in pages {
                group.addTask {
                    let thumbnail = await loader.thumbnail(
                        forPageAt: page, size: cell, displayScale: ThumbnailGeometry.displayScale
                    )
                    return thumbnail?.cgImage.map { $0.bytesPerRow * $0.height }
                }
            }
            var byteCounts: [Int] = []
            for await byteCount in group {
                if let byteCount { byteCounts.append(byteCount) }
            }
            return byteCounts
        }
    }
}
