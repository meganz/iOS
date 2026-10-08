import MEGABenchmark
@testable import MEGAMarkdownEditor
import XCTest

/// The chrome of every rich row, built from scratch. The editor does this after a change to a list or quote.
/// They run only with `TEST_RUNNER_MEGA_BENCH=1`.
final class RichChromeIndexBenchmarks: BenchmarkCase {
    /// 167,000 rows: a file at the rich limit (500,000 UTF-16 units) of 3-character rows.
    /// Most rows are list items and quotes, the slow kinds for the index.
    private static let blocks: [RichBlock] = {
        let text = RichText("abc")
        let pattern: [RichBlock] = [
            .paragraph(text),
            .listItem(RichListItem(isOrdered: false, indent: 0), text: text),
            .listItem(RichListItem(isOrdered: false, indent: 1), text: text),
            .listItem(RichListItem(isOrdered: true, indent: 2), text: text),
            .listItem(RichListItem(isOrdered: true, indent: 2), text: text),
            .listItem(RichListItem(isOrdered: false, indent: 0, isChecked: false), text: text),
            .listItem(RichListItem(isOrdered: false, indent: 0, isChecked: true), text: text),
            .quote(depth: 1, text: text),
            .quote(depth: 2, text: text),
            .quote(depth: 1, text: text)
        ]
        return (0..<16_700).flatMap { _ in pattern }
    }()

    /// The whole index: the load builds it once.
    func testRebuildAt167kRows() {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            let numbers = RichDocument.orderedNumbers(of: Self.blocks)
            XCTAssertEqual(RichChromeIndex(blocks: Self.blocks, numbers: numbers).count, 167_000)
        }
    }

    /// Enter in a list in the middle of the file: only the list and quote rows around it are built again.
    func testUpdateAfterEnterAt167kRows() {
        var editor = RichEditor(newFile: RichDocument(blocks: Self.blocks))
        let index = RichChromeIndex(blocks: Self.blocks, numbers: RichDocument.orderedNumbers(of: Self.blocks))
        editor.select(.caret(RichPosition(blockIndex: 83_502, offset: 1)))
        editor.insertParagraphBreak()
        guard let change = editor.lastChange else { return XCTFail("no change") }
        let blocks = editor.rows.map(\.block)
        // The copy of the index is not measured: the editor updates its own index in place.
        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()], options: options) {
            var updated = index
            // An empty change makes the copy of the index here, so the timed call does not pay for it.
            updated.apply(RichEditor.RowChange(oldRange: 0..<0, newCount: 0), blocks: Self.blocks)
            startMeasuring()
            updated.apply(change, blocks: blocks)
            stopMeasuring()
            XCTAssertEqual(updated.count, 167_001)
        }
    }
}
