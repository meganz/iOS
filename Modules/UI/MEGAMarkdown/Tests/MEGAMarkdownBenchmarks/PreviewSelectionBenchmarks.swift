import MEGABenchmark
@testable import MEGAMarkdown
import QuartzCore
import SwiftUI
import UIKit
import XCTest

/// Block selection on a 10 MB text, parsed and shown before each measure. Run with `TEST_RUNNER_MEGA_BENCH=1`.
/// The scroll test has a twin without a selection, so the cost of the selection display shows as the difference.
@MainActor
final class PreviewSelectionBenchmarks: BenchmarkCase {
    private static let tenMegabytes = BenchmarkDocuments.makeLargeDocument(targetBytes: 10_000_000)
    private static let screensToScroll = 100

    private var manualOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        return options
    }

    /// 100 screens down while Select All is active: every new row asks the selection display for its rects.
    func testScrollWithSelectAllTenMegabytes() throws {
        try measureScroll(selectAll: true)
    }

    func testScrollWithoutASelectionTenMegabytes() throws {
        try measureScroll(selectAll: false)
    }

    /// The plain text of Select All on the whole 10 MB text.
    func testCopySelectAllTenMegabytes() throws {
        var failure: (any Error)?
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()], options: manualOptions) {
            do {
                let (window, list, coordinator) = try open()
                coordinator.selection.selectAll()
                startMeasuring()
                let text = coordinator.selection.selectedText() ?? ""
                stopMeasuring()
                XCTAssertGreaterThan(text.utf8.count, 5_000_000)
                _ = list
                PreviewCellBenchmarks.close(window)
            } catch {
                failure = error
                stopMeasuring()
            }
        }
        if let failure { throw failure }
    }

    private func measureScroll(selectAll: Bool) throws {
        var failure: (any Error)?
        let metrics: [any XCTMetric] = [XCTClockMetric(), MainThreadStallMetric(), FrameHitchMetric(), PeakFootprintMetric()]
        measure(metrics: metrics, options: manualOptions) {
            do {
                let (window, list, coordinator) = try open()
                if selectAll {
                    coordinator.selection.selectAll()
                    try turnMainLoop(timeout: 30) { coordinator.selection.isDisplayActive }
                }
                startMeasuring()
                for _ in 0..<Self.screensToScroll {
                    list.contentOffset.y += list.bounds.height
                    list.layoutIfNeeded()
                    CATransaction.flush()
                    turnMainLoop(for: 0.001)
                }
                stopMeasuring()
                XCTAssertGreaterThan(list.indexPathsForVisibleItems.map(\.item).min() ?? 0, 0)
                PreviewCellBenchmarks.close(window)
            } catch {
                failure = error
                stopMeasuring()
            }
        }
        if let failure { throw failure }
    }

    /// The preview in a window, with every row parsed.
    private func open() throws -> (UIWindow, MarkdownRowListView, PreviewRowList.Coordinator) {
        let host = UIHostingController(rootView: MarkdownPreview(Self.tenMegabytes))
        host.view.frame = CGRect(origin: .zero, size: PreviewCellBenchmarks.phoneSize)
        let window = PreviewCellBenchmarks.window(showing: host)
        var found: (MarkdownRowListView, PreviewRowList.Coordinator)?
        try turnMainLoop(timeout: 120) {
            guard let list = PreviewListHarness.list(in: window), let coordinator = list.delegate as? PreviewRowList.Coordinator,
                  coordinator.isComplete, !list.visibleCells.isEmpty else { return false }
            found = (list, coordinator)
            return true
        }
        guard let found else { throw MainLoopError.timeout(seconds: 120) }
        CATransaction.flush()
        return (window, found.0, found.1)
    }
}
