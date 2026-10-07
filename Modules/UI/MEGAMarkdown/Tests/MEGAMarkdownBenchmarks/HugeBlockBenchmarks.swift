import MEGABenchmark
@testable import MEGAMarkdown
import SwiftUI
import UIKit
import XCTest

/// Files that are one huge block (see `BenchmarkDocuments.HugeBlock`): from a new `MarkdownPreview` to the first rows.
/// A file of one block has no safe cut, so it is one chunk, and the first rows wait for the whole parse.
/// Run: `scripts/benchmark.sh ... --only HugeBlockBenchmarks`.
@MainActor
final class HugeBlockBenchmarks: BenchmarkCase {
    private var metrics: [any XCTMetric] {
        [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()]
    }

    func testOpenTable() throws { try measureOpen(.table) }
    func testOpenList() throws { try measureOpen(.list) }
    func testOpenCodeBlock() throws { try measureOpen(.code) }
    func testOpenQuote() throws { try measureOpen(.quote) }
    func testOpenParagraph() throws { try measureOpen(.paragraph) }
    func testOpenLineWithNoSpace() throws { try measureOpen(.line) }

    private func measureOpen(_ block: BenchmarkDocuments.HugeBlock) throws {
        let markdown = block.markdown
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        options.invocationOptions = [.manuallyStop]
        var failure: (any Error)?
        measure(metrics: metrics, options: options) {
            let controller = UIHostingController(rootView: MarkdownPreview(markdown))
            controller.view.frame = CGRect(origin: .zero, size: PreviewCellBenchmarks.phoneSize)
            let window = PreviewCellBenchmarks.window(showing: controller)
            do {
                try turnMainLoop(timeout: 120) { PreviewListHarness.list(in: window)?.visibleCells.isEmpty == false }
            } catch {
                failure = error
            }
            CATransaction.flush()
            stopMeasuring()
            PreviewCellBenchmarks.close(window)
        }
        if let failure { throw failure }
    }
}
