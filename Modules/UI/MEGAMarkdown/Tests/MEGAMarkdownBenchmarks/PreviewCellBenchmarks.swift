import MEGABenchmark
@testable import MEGAMarkdown
import QuartzCore
import UIKit
import XCTest

/// Split preview rows of a 40 KB document in the production `PreviewRowList`, each row a hosted SwiftUI cell.
/// Every block is split, so each cell draws one short piece. Run: `scripts/benchmark.sh`.
/// `Limits.json` has no entry for these tests, so a run records the numbers and checks nothing.
@MainActor
final class PreviewCellBenchmarks: BenchmarkCase {
    static let phoneSize = CGSize(width: 402, height: 874)
    private static let documentBytes = 40_000

    private static func rows(targetBytes: Int) -> [PreviewRow] {
        let markdown = BenchmarkDocuments.makeLargeDocument(targetBytes: targetBytes)
        return PreviewRows.rows(for: CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [], maxWeight: 0)
    }

    // MARK: - Open

    func testOpenAllHosted() throws {
        try measureOpen()
    }

    /// From a new list in a window to the first committed frame, with the height estimates of all rows.
    /// The block blocks the main thread, so the stall is the wait.
    private func measureOpen() throws {
        let rows = Self.rows(targetBytes: Self.documentBytes)
        let options = XCTMeasureOptions.default
        options.invocationOptions = [.manuallyStop]
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()], options: options) {
            let (window, harness) = Self.open(rows: rows)
            stopMeasuring()
            Self.checkFirstScreen(of: harness)
            Self.close(window)
        }
    }

    // MARK: - Scroll

    func testScrollAllHosted() throws {
        try measureScroll()
    }

    /// One screen per step from the top to the end. The main run loop turns between steps,
    /// so the longest stall is the slowest step.
    private func measureScroll() throws {
        let rows = Self.rows(targetBytes: Self.documentBytes)
        let options = XCTMeasureOptions.default
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()], options: options) {
            let (window, harness) = Self.open(rows: rows)
            startMeasuring()
            let steps = scrollToEnd(harness.collectionView)
            stopMeasuring()
            // The time only means something if the list really reached its last row.
            XCTAssertGreaterThan(steps, 10)
            XCTAssertTrue(harness.collectionView.indexPathsForVisibleItems.contains(IndexPath(item: rows.count - 1, section: 0)))
            Self.close(window)
        }
    }

    private func scrollToEnd(_ collectionView: UICollectionView) -> Int {
        var steps = 0
        // Cells that size themselves change the content size while it scrolls, so the end is read again each step.
        while steps < 100_000 {
            collectionView.layoutIfNeeded()
            let end = collectionView.contentSize.height - collectionView.bounds.height
            guard collectionView.contentOffset.y < end - 0.5 else { break }
            collectionView.contentOffset.y = min(collectionView.contentOffset.y + collectionView.bounds.height, end)
            collectionView.layoutIfNeeded()
            CATransaction.flush()
            turnMainLoop(for: 0.001)
            steps += 1
        }
        return steps
    }

    // MARK: - Helpers

    static func open(rows: [PreviewRow]) -> (UIWindow, PreviewListHarness) {
        let harness = PreviewListHarness(store: PreviewRowStore(rows: rows), frame: CGRect(origin: .zero, size: phoneSize))
        let window = window(showing: harness.rootViewController)
        harness.rootViewController.view.layoutIfNeeded()
        CATransaction.flush()
        return (window, harness)
    }

    static func window(showing controller: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(origin: .zero, size: phoneSize))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        return window
    }

    static func close(_ window: UIWindow) {
        window.rootViewController = nil
        window.isHidden = true
    }

    /// The first screen shows the first row and fills the screen.
    static func checkFirstScreen(of harness: PreviewListHarness) {
        let visible = harness.collectionView.indexPathsForVisibleItems.map(\.item).sorted()
        XCTAssertEqual(visible.first, 0)
        XCTAssertGreaterThan(visible.count, 5)
    }
}
