import MEGABenchmark
@testable import MEGAMarkdown
import QuartzCore
import UIKit
import XCTest

/// Changes in the middle of a long `MarkdownRowList`, as a caller that edits its rows makes them.
/// Run: `scripts/benchmark.sh ... --only MarkdownRowListBenchmarks`.
@MainActor
final class MarkdownRowListBenchmarks: BenchmarkCase {
    private static let itemCount = 200_000
    private static let replacements = 100

    /// One measured run replaces item 100,000 by two items 100 times, each with its layout pass.
    /// The middle replace rebuilds the height tree, O(n). Time per replace = the clock time / 100.
    func testReplaceMiddleItemOf200kItems() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        var perReplace: [Double] = []
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric()], options: options) {
            let source = PlainRowSource(count: Self.itemCount)
            let list = MarkdownRowList(dataSource: source)
            list.view.contentInsetAdjustmentBehavior = .never
            let controller = UIViewController()
            controller.view = list.view
            let window = PreviewCellBenchmarks.window(showing: controller)
            list.reloadAll()
            let middle = Self.itemCount / 2
            list.scrollToItem(middle, rect: nil) {}
            CATransaction.flush()

            let start = ContinuousClock.now
            startMeasuring()
            for _ in 0..<Self.replacements {
                source.count += 1
                list.replaceItems(middle..<(middle + 1), newCount: 2, keepingFirst: 1)
                list.view.layoutIfNeeded()
            }
            stopMeasuring()
            let elapsed = ContinuousClock.now - start
            perReplace.append(Double(elapsed.components.attoseconds) / 1e15 / Double(Self.replacements)
                + Double(elapsed.components.seconds) * 1_000 / Double(Self.replacements))

            XCTAssertEqual(list.itemCount, Self.itemCount + Self.replacements)
            XCTAssertNotNil(list.cell(forItem: middle))
            PreviewCellBenchmarks.close(window)
        }
        let average = perReplace.reduce(0, +) / Double(max(perReplace.count, 1))
        print("[MarkdownRowListBenchmarks] replace middle of \(Self.itemCount) items: \(String(format: "%.3f", average)) ms per replace")
    }

    /// One parse batch added at the end of a list that already shows 20 batches, as while a large file loads.
    /// The 20 batches are 20 sections, built with `appendItems` like the preview does.
    /// The batch size is the row count of a 1 MB preview parse, so it matches what the preview appends.
    func testAppendParseBatchAfter20Batches() throws {
        let batchRows = Self.rowsInOneMegabyteParse()
        let existing = batchRows * 20
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        var perAppend: [Double] = []
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric()], options: options) {
            let source = PlainRowSource(count: batchRows)
            let list = MarkdownRowList(dataSource: source)
            list.view.contentInsetAdjustmentBehavior = .never
            let controller = UIViewController()
            controller.view = list.view
            let window = PreviewCellBenchmarks.window(showing: controller)
            list.reloadAll()
            for _ in 1..<20 {
                source.count += batchRows
                list.appendItems(count: batchRows)
            }
            list.view.layoutIfNeeded()
            CATransaction.flush()
            XCTAssertEqual(list.view.numberOfSections, 20)

            source.count += batchRows
            let start = ContinuousClock.now
            startMeasuring()
            list.appendItems(count: batchRows)
            list.view.layoutIfNeeded()
            stopMeasuring()
            let elapsed = ContinuousClock.now - start
            perAppend.append(Double(elapsed.components.attoseconds) / 1e15 + Double(elapsed.components.seconds) * 1_000)

            XCTAssertEqual(list.itemCount, existing + batchRows)
            XCTAssertEqual(list.view.numberOfSections, 21)
            XCTAssertNotNil(list.cell(forItem: 0))
            PreviewCellBenchmarks.close(window)
        }
        let average = perAppend.reduce(0, +) / Double(max(perAppend.count, 1))
        print("[MarkdownRowListBenchmarks] append \(batchRows) items to \(existing): \(String(format: "%.3f", average)) ms per append")
    }

    /// The rows of one 1 MB chunk, the parse batch size of `MarkdownChunker`.
    private static func rowsInOneMegabyteParse() -> Int {
        let markdown = BenchmarkDocuments.makeLargeDocument(targetBytes: MarkdownChunker.defaultTargetBytes)
        var rows = 0
        _ = PreviewPipeline.parse(MarkdownParseRequest(markdown: markdown), limits: PreviewParseLimits()) { batch in
            rows += batch.rows.count
        }
        return rows
    }

    /// Only the height tree part of the replace above: 100 middle replaces of 1 item by 2 in 200,000 heights.
    func testReplaceMiddleHeightOf200kItems() {
        var perReplace: [Double] = []
        measure(metrics: [XCTClockMetric()]) {
            var heights = MarkdownRowHeights(heights: Array(repeating: 44, count: Self.itemCount))
            let middle = Self.itemCount / 2
            let start = ContinuousClock.now
            for _ in 0..<Self.replacements {
                heights.replaceSubrange(middle..<(middle + 1), with: [44, 30])
            }
            let elapsed = ContinuousClock.now - start
            perReplace.append(Double(elapsed.components.attoseconds) / 1e15 / Double(Self.replacements)
                + Double(elapsed.components.seconds) * 1_000 / Double(Self.replacements))
            XCTAssertEqual(heights.count, Self.itemCount + Self.replacements)
        }
        let average = perReplace.reduce(0, +) / Double(max(perReplace.count, 1))
        print("[MarkdownRowListBenchmarks] height tree replace in \(Self.itemCount) items: \(String(format: "%.3f", average)) ms per replace")
    }
}

/// Plain UIKit rows, so the time is the container's own work.
@MainActor
private final class PlainRowSource: MarkdownRowListDataSource {
    var count: Int

    init(count: Int) {
        self.count = count
    }

    var itemCount: Int { count }

    func configure(_ cell: MarkdownRowCell, forItem item: Int) {
        var content = UIListContentConfiguration.cell()
        content.text = "Item \(item)"
        cell.contentConfiguration = content
    }

    func estimatedHeight(ofItem item: Int, using estimator: MarkdownRowEstimator) -> CGFloat {
        44
    }

    func alwaysSizes(item: Int) -> Bool {
        false
    }
}
