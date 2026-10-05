import MEGABenchmark
import PDFKit
import XCTest

/// Concurrent `PDFPage.thumbnail(of:for:)` renders, called the way
/// `PDFThumbnailLoader` calls it. They run only with
/// `TEST_RUNNER_MEGA_BENCH=1`. Limits: `Limits.json` next to this file.
@MainActor
final class PDFPageConcurrentRenderBenchmarks: BenchmarkCase {
    private static let renderCount = BenchmarkDocuments.pageCount

    /// Every render asks for page 0, so all of them wait on that page.
    func testConcurrentRendersOfSamePage() throws {
        let url = try BenchmarkDocuments.makeScannedDocument()
        let pages = Array(repeating: 0, count: Self.renderCount)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            let rendered = try? runOnMainLoop { await Self.renderConcurrently(url: url, pages: pages) }
            XCTAssertEqual(rendered, pages.count)
        }
    }

    /// Every render asks for a different page of one document, as the grid
    /// does.
    func testConcurrentRendersOfDistinctPages() throws {
        let url = try BenchmarkDocuments.makeScannedDocument()
        let pages = Array(0..<Self.renderCount)
        // No wall-clock metric: these renders run in parallel, so their time
        // depends on how many cores the host has free, which CI does not pin.
        // No benchmark measures the speed-up from rendering concurrently; the
        // CPU metrics cover only the cost of each render.
        measure(metrics: [XCTCPUMetric()]) {
            let rendered = try? runOnMainLoop { await Self.renderConcurrently(url: url, pages: pages) }
            XCTAssertEqual(rendered, pages.count)
        }
    }

    /// `PDFThumbnailLoader` relies on PDFKit serialising renders per page,
    /// not per document. Uses the fastest of 3 runs.
    func testDistinctPagesRenderFasterThanSamePage() throws {
        let url = try BenchmarkDocuments.makeScannedDocument()
        let samePage = try fastest(url: url, pages: Array(repeating: 0, count: Self.renderCount))
        let distinctPages = try fastest(url: url, pages: Array(0..<Self.renderCount))
        XCTAssertLessThan(distinctPages * 2, samePage, "same page \(samePage), distinct pages \(distinctPages)")
    }

    // MARK: - Helpers

    private func fastest(url: URL, pages: [Int]) throws -> Duration {
        try (0..<3).map { _ in
            try ContinuousClock().measure {
                // The time only means something if every render produced a
                // thumbnail.
                let rendered = try runOnMainLoop { await Self.renderConcurrently(url: url, pages: pages) }
                XCTAssertEqual(rendered, pages.count)
            }
        }.min() ?? .zero
    }

    private static func renderConcurrently(url: URL, pages: [Int]) async -> Int {
        guard let document = PDFDocument(url: url) else { return 0 }
        let pixelSize = ThumbnailGeometry.pixelSize(of: ThumbnailGeometry.portraitCell)
        let sendablePages = pages.compactMap { document.page(at: $0) }.map(UncheckedSendablePage.init)
        return await withTaskGroup(of: Bool.self) { group in
            for page in sendablePages {
                group.addTask { await render(page: page, pixelSize: pixelSize) }
            }
            var count = 0
            for await rendered in group where rendered { count += 1 }
            return count
        }
    }

    @concurrent
    private nonisolated static func render(page: UncheckedSendablePage, pixelSize: CGSize) async -> Bool {
        let thumbnail = page.page.thumbnail(of: pixelSize, for: .cropBox)
        return thumbnail.size.width > 0
    }
}

// `PDFPage` is not Sendable. Its only off-main use is the render above.
private struct UncheckedSendablePage: @unchecked Sendable {
    let page: PDFPage
}
