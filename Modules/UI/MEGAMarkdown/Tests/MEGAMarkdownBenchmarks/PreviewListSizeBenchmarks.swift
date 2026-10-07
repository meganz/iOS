import MEGABenchmark
@testable import MEGAMarkdown
import QuartzCore
import SwiftUI
import UIKit
import XCTest

/// The preview of big documents, one class per document size.
/// List tests show rows that are already parsed in the production `PreviewRowList`, so they measure the list only.
/// `testOpenToFirstContent` and `testLoadWhileShown` run the whole `MarkdownPreview`, parse included.
/// `Limits.json` limits the stall and late frame metrics of every class here, and `Peak Heap Growth` of the scroll tests.
/// `Peak Footprint` has no limit: it has no direction, so the report shows it and no gate checks it.
/// Run one size: `scripts/benchmark.sh ... --only PreviewListTwoMegabyteBenchmarks`.
/// Known edge cases have a stall limit above 100 ms and allow stalls over 100 ms: the `testOpen` tests of the 10, 50 and 100 MB classes,
/// and `testJumpIntoBigTable` and `testScroll` of the 100 MB class.
/// The 100 MB `testFling` allows 30 late frames. The limits record today's numbers, so a fix should lower them.
@MainActor
class PreviewListSizeBenchmarkCase: BenchmarkCase {
    /// The document size of the subclass, and the measured runs for it. Bigger documents run fewer times.
    var documentBytes: Int { 0 }
    var iterations: Int { 5 }

    private static let screensToScroll = 100
    /// 3 s at 60 frames per second, 60 pt per frame: about the speed of a fast fling.
    private static let flingFrames = 180
    private static let flingStep: CGFloat = 60
    private static let framesPerBatch = 20
    /// The text and rows of the last size, so the tests of one class make them once.
    private static var cached: (bytes: Int, markdown: String, store: PreviewRowStore, batchEnds: [Int])?

    func makeMarkdown() -> String {
        BenchmarkDocuments.makeLargeDocument(targetBytes: documentBytes)
    }

    var markdown: String { cachedDocument().markdown }
    var store: PreviewRowStore { cachedDocument().store }
    /// The row count after each parse batch.
    var batchEnds: [Int] { cachedDocument().batchEnds }

    private func cachedDocument() -> (bytes: Int, markdown: String, store: PreviewRowStore, batchEnds: [Int]) {
        if let cached = Self.cached, cached.bytes == documentBytes { return cached }
        Self.cached = nil
        let markdown = makeMarkdown()
        let (store, batchEnds) = PreviewListHarness.batchedStore(for: markdown)
        print("[PreviewListSizeBenchmarks] bytes=\(markdown.utf8.count) rows=\(store.count) batches=\(batchEnds.count)")
        Self.cached = (documentBytes, markdown, store, batchEnds)
        return (documentBytes, markdown, store, batchEnds)
    }

    private func options(manuallyStart: Bool) -> XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = iterations
        options.invocationOptions = manuallyStart ? [.manuallyStart, .manuallyStop] : [.manuallyStop]
        return options
    }

    private var metrics: [any XCTMetric] {
        [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()]
    }

    private static func open(_ store: PreviewRowStore, batchEnds: [Int] = []) -> (UIWindow, PreviewListHarness) {
        let harness = PreviewListHarness(store: store, frame: CGRect(origin: .zero, size: PreviewCellBenchmarks.phoneSize), batchEnds: batchEnds)
        let window = PreviewCellBenchmarks.window(showing: harness.rootViewController)
        harness.rootViewController.view.layoutIfNeeded()
        harness.collectionView.layoutIfNeeded()
        CATransaction.flush()
        return (window, harness)
    }

    // MARK: - Whole preview

    /// From a new `MarkdownPreview` in a window to the first visible rows. The parse runs off the main thread,
    /// so the main run loop turns until the rows show. Only the first chunk is parsed by then.
    func measureOpenToFirstContent() throws {
        let markdown = markdown
        try measureWholePreview(markdown) { list in !(list?.visibleCells.isEmpty ?? true) }
    }

    /// From a new `MarkdownPreview` to every row in the list. The longest stall is the slowest batch on the main thread.
    func measureLoadWhileShown() throws {
        let markdown = markdown
        let count = store.count
        try measureWholePreview(markdown) { list in
            (list?.delegate as? PreviewRowList.Coordinator)?.list.itemCount == count
        }
    }

    private func measureWholePreview(_ markdown: String, until isDone: @escaping (MarkdownRowListView?) -> Bool) throws {
        var failure: (any Error)?
        measure(metrics: metrics, options: options(manuallyStart: false)) {
            let controller = UIHostingController(rootView: MarkdownPreview(markdown))
            controller.view.frame = CGRect(origin: .zero, size: PreviewCellBenchmarks.phoneSize)
            let window = PreviewCellBenchmarks.window(showing: controller)
            do {
                try turnMainLoop(timeout: 120) { isDone(PreviewListHarness.list(in: window)) }
            } catch {
                failure = error
            }
            CATransaction.flush()
            stopMeasuring()
            PreviewCellBenchmarks.close(window)
        }
        if let failure { throw failure }
    }

    // MARK: - List

    /// From a new list in a window to the first committed frame. Every row is estimated, as for a text of one chunk.
    func measureOpen() {
        let store = store
        measure(metrics: metrics, options: options(manuallyStart: false)) {
            let (window, harness) = Self.open(store)
            stopMeasuring()
            PreviewCellBenchmarks.checkFirstScreen(of: harness)
            PreviewCellBenchmarks.close(window)
        }
    }

    /// 100 screens from the top, one screen per step. The main run loop turns between steps.
    func measureScroll() {
        let store = store
        measure(metrics: metrics, options: options(manuallyStart: true)) {
            let (window, harness) = Self.open(store)
            let collectionView = harness.collectionView
            startMeasuring()
            var steps = 0
            while steps < Self.screensToScroll {
                collectionView.contentOffset.y += collectionView.bounds.height
                collectionView.layoutIfNeeded()
                CATransaction.flush()
                turnMainLoop(for: 0.001)
                steps += 1
            }
            stopMeasuring()
            XCTAssertEqual(steps, Self.screensToScroll)
            // The list is longer than 100 screens, so every step showed new rows.
            XCTAssertGreaterThanOrEqual(collectionView.contentSize.height, collectionView.contentOffset.y + collectionView.bounds.height)
            XCTAssertGreaterThan(collectionView.indexPathsForVisibleItems.map(\.item).min() ?? 0, 0)
            PreviewCellBenchmarks.close(window)
        }
    }

    /// A steady scroll of 60 pt per frame for 180 frames, with the display link running. Late frames show main-thread hitches.
    func measureFling() {
        let store = store
        let metrics: [any XCTMetric] = [XCTClockMetric(), MainThreadStallMetric(), FrameHitchMetric()]
        measure(metrics: metrics, options: options(manuallyStart: true)) {
            let (window, harness) = Self.open(store)
            let collectionView = harness.collectionView
            startMeasuring()
            for _ in 0..<Self.flingFrames {
                collectionView.contentOffset.y += Self.flingStep
                turnMainLoop(for: 1.0 / 60)
            }
            stopMeasuring()
            XCTAssertGreaterThan(collectionView.indexPathsForVisibleItems.map(\.item).min() ?? 0, 0)
            PreviewCellBenchmarks.close(window)
        }
    }

    /// From the top straight to the last row. Cells that size themselves move the end, so it scrolls again until the row shows.
    func measureJumpToEnd() {
        measureJump(to: store.count - 1)
    }

    /// From the top straight to row `index`, at the top of the screen, or at the bottom for the last row.
    func measureJump(to index: Int) {
        let store = store
        let position: UICollectionView.ScrollPosition = index == store.count - 1 ? .bottom : .top
        measure(metrics: metrics, options: options(manuallyStart: true)) {
            let (window, harness) = Self.open(store)
            let collectionView = harness.collectionView
            let target = harness.indexPath(ofRow: index)
            startMeasuring()
            var tries = 0
            while tries < 20, !collectionView.indexPathsForVisibleItems.contains(target) {
                harness.scroll(toRow: index, at: position)
                collectionView.layoutIfNeeded()
                CATransaction.flush()
                turnMainLoop(for: 0.001)
                tries += 1
            }
            stopMeasuring()
            XCTAssertTrue(collectionView.indexPathsForVisibleItems.contains(target), "after \(tries) tries")
            PreviewCellBenchmarks.close(window)
        }
    }

    // MARK: - Loaded in batches

    /// Appends every batch the list does not show yet, each in a new section, as while a file loads.
    private static func appendRemainingBatches(to harness: PreviewListHarness) {
        while harness.hasMoreBatches {
            harness.loadNextBatch()
            harness.rootViewController.view.layoutIfNeeded()
            CATransaction.flush()
        }
    }

    /// The same steady fling as `measureFling`. A new batch is appended every 20 frames, so a fling meets the appends.
    func measureFlingWhileBatchesAppend() {
        let store = store
        let batchEnds = batchEnds
        XCTAssertGreaterThan(batchEnds.count, 1, "the document must load in more than one batch")
        let metrics: [any XCTMetric] = [XCTClockMetric(), MainThreadStallMetric(), FrameHitchMetric()]
        measure(metrics: metrics, options: options(manuallyStart: true)) {
            let (window, harness) = Self.open(store, batchEnds: batchEnds)
            let collectionView = harness.collectionView
            startMeasuring()
            for frame in 0..<Self.flingFrames {
                if frame % Self.framesPerBatch == 0 { harness.loadNextBatch() }
                collectionView.contentOffset.y += Self.flingStep
                turnMainLoop(for: 1.0 / 60)
            }
            stopMeasuring()
            XCTAssertGreaterThan(collectionView.numberOfSections, 1)
            XCTAssertGreaterThan(collectionView.indexPathsForVisibleItems.map(\.item).min() ?? 0, 0)
            PreviewCellBenchmarks.close(window)
        }
    }

    /// From the top straight to the last row of a list that was loaded in batches. The layout has one section per batch.
    func measureJumpToEndAfterBatchLoad() {
        let store = store
        let batchEnds = batchEnds
        let index = store.count - 1
        measure(metrics: metrics, options: options(manuallyStart: true)) {
            let (window, harness) = Self.open(store, batchEnds: batchEnds)
            Self.appendRemainingBatches(to: harness)
            let collectionView = harness.collectionView
            let target = harness.indexPath(ofRow: index)
            startMeasuring()
            var tries = 0
            while tries < 20, !collectionView.indexPathsForVisibleItems.contains(target) {
                harness.scroll(toRow: index, at: .bottom)
                collectionView.layoutIfNeeded()
                CATransaction.flush()
                turnMainLoop(for: 0.001)
                tries += 1
            }
            stopMeasuring()
            XCTAssertGreaterThan(collectionView.numberOfSections, 1)
            XCTAssertTrue(collectionView.indexPathsForVisibleItems.contains(target), "after \(tries) tries")
            PreviewCellBenchmarks.close(window)
        }
    }

    // MARK: - Changes of the environment

    /// The list is open on the first screen. `change` runs inside the measured interval, then the list lays out once.
    private func measureChange(_ change: @escaping @MainActor (PreviewListHarness) -> Void) {
        let store = store
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric()], options: options(manuallyStart: true)) {
            let (window, harness) = Self.open(store)
            startMeasuring()
            change(harness)
            harness.rootViewController.view.layoutIfNeeded()
            harness.collectionView.layoutIfNeeded()
            CATransaction.flush()
            turnMainLoop(for: 0.001)
            stopMeasuring()
            PreviewCellBenchmarks.checkFirstScreen(of: harness)
            PreviewCellBenchmarks.close(window)
        }
    }

    /// A narrower list, as after a rotation or a split view change. The width is part of every height.
    func measureWidthChange() {
        measureChange { harness in
            harness.rootViewController.view.frame.size.width = 320
        }
    }

    /// The text size of the SwiftUI environment goes to the hosted rows and to the height guesses.
    func measureTextSizeChange() {
        measureChange { $0.textSize = .accessibility2 }
    }

    /// A theme with another body font makes every height a guess again.
    func measureThemeChange() {
        measureChange { harness in
            var theme = MarkdownTheme.default
            theme.bodyFont = .system(size: 22)
            harness.theme = theme
        }
    }

    // MARK: - Memory

    /// Scrolls 2,000 screens in steps of 10. The heap in use must grow by less than 100 MiB.
    /// The heap grows about 24 MiB per 1,000 screens in the simulator, also for rows seen before.
    /// A scroll to the end of 50 MB (about 105,000 screens) would reach about 3 GB, so it is not asserted.
    func measureMemoryOverLongScroll() {
        let store = store
        let options = options(manuallyStart: true)
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()], options: options) {
            let (window, harness) = Self.open(store)
            let collectionView = harness.collectionView
            let screen = collectionView.bounds.height
            startMeasuring()
            let heapAtStart = Footprint.heapMiB()
            for _ in 0..<200 {
                collectionView.contentOffset.y += screen * 10
                collectionView.layoutIfNeeded()
                CATransaction.flush()
                turnMainLoop(for: 0.001)
            }
            let growth = Footprint.heapMiB() - heapAtStart
            stopMeasuring()
            print("[PreviewListSizeBenchmarks] heap grew \(Int(growth)) MiB over 2000 screens")
            XCTAssertLessThan(growth, 100)
            PreviewCellBenchmarks.close(window)
        }
    }
}

// MARK: - 2 MB

final class PreviewListTwoMegabyteBenchmarks: PreviewListSizeBenchmarkCase {
    override var documentBytes: Int { 2_000_000 }
    override var iterations: Int { 5 }

    func testOpenToFirstContent() throws { try measureOpenToFirstContent() }
    func testLoadWhileShown() throws { try measureLoadWhileShown() }
    func testOpen() { measureOpen() }
    func testScroll() { measureScroll() }
    func testFling() { measureFling() }
    func testJumpToEnd() { measureJumpToEnd() }
}

// MARK: - 10 MB

final class PreviewListTenMegabyteBenchmarks: PreviewListSizeBenchmarkCase {
    override var documentBytes: Int { 10_000_000 }
    override var iterations: Int { 3 }

    func testOpenToFirstContent() throws { try measureOpenToFirstContent() }
    func testLoadWhileShown() throws { try measureLoadWhileShown() }
    func testOpen() { measureOpen() }
    func testScroll() { measureScroll() }
    func testFling() { measureFling() }
    func testJumpToEnd() { measureJumpToEnd() }
    func testFlingWhileBatchesAppend() { measureFlingWhileBatchesAppend() }
    func testJumpToEndAfterBatchLoad() { measureJumpToEndAfterBatchLoad() }
    func testWidthChange() { measureWidthChange() }
    func testTextSizeChange() { measureTextSizeChange() }
    func testThemeChange() { measureThemeChange() }
}

// MARK: - 50 MB

final class PreviewListFiftyMegabyteBenchmarks: PreviewListSizeBenchmarkCase {
    override var documentBytes: Int { 50_000_000 }
    override var iterations: Int { 2 }

    func testOpenToFirstContent() throws { try measureOpenToFirstContent() }
    func testOpen() { measureOpen() }
    func testScroll() { measureScroll() }
    func testFling() { measureFling() }
    func testJumpToEnd() { measureJumpToEnd() }
    func testMemoryOverLongScroll() { measureMemoryOverLongScroll() }
}

// MARK: - 100 MB, every block kind

/// Every block kind and big blocks (see `BenchmarkDocuments.makeAllKindsDocument`).
/// A part with no safe cut becomes plain text rows, and the chunker ends the file there.
final class PreviewListHundredMegabyteBenchmarks: PreviewListSizeBenchmarkCase {
    override var documentBytes: Int { 100_000_000 }
    override var iterations: Int { 2 }

    override func makeMarkdown() -> String {
        BenchmarkDocuments.makeAllKindsDocument(targetBytes: documentBytes)
    }

    func testOpenToFirstContent() throws { try measureOpenToFirstContent() }
    func testOpen() { measureOpen() }
    func testScroll() { measureScroll() }
    func testFling() { measureFling() }
    func testJumpToEnd() { measureJumpToEnd() }
    func testJumpIntoBigCode() { measureJump(to: middleOfFirstRun(atLeast: 1_000, of: Self.isCodePiece)) }
    func testJumpIntoBigTable() { measureJump(to: middleOfFirstRun(atLeast: 1_000, of: Self.isTablePage)) }

    /// The middle row of the first run of at least `length` rows that match. A big block is such a run.
    private func middleOfFirstRun(atLeast length: Int, of matches: (PreviewRow) -> Bool) -> Int {
        let store = store
        var start = 0
        for index in 0..<store.count {
            if !matches(store[index]) {
                start = index + 1
            } else if index - start + 1 >= length, index + 1 == store.count || !matches(store[index + 1]) {
                return (start + index) / 2
            }
        }
        XCTFail("no run of \(length) rows")
        return 0
    }

    private static func isCodePiece(_ row: PreviewRow) -> Bool {
        if case .codePiece = row.content { return true }
        return false
    }

    private static func isTablePage(_ row: PreviewRow) -> Bool {
        if case .tablePage = row.content { return true }
        return false
    }
}
