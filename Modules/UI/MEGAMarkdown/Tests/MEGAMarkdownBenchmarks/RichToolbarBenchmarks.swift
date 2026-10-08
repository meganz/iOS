import MEGABenchmark
@testable import MEGAMarkdownEditor
import XCTest

/// The toolbar state is read after every model action. After Select All it looks at every row.
/// They run only with `TEST_RUNNER_MEGA_BENCH=1`.
final class RichToolbarBenchmarks: BenchmarkCase {
    /// 167,000 rows of 3 characters: 501,000 UTF-16 units, just over the rich limit of 500,000. Every row is bold.
    private static let blocks: [RichBlock] = {
        let text = RichText("abc", spans: [RichSpan(range: 0..<3, style: .bold)])
        let pattern: [RichBlock] = [
            .paragraph(text),
            .listItem(RichListItem(isOrdered: false, indent: 0), text: text),
            .quote(depth: 1, text: text)
        ]
        return (0..<55_667).flatMap { _ in pattern }.prefix(167_000).map { $0 }
    }()

    func testToolbarAfterSelectAllAt167kRows() {
        var editor = RichEditor(newFile: RichDocument(blocks: Self.blocks))
        editor.selectAll()
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            XCTAssertEqual(RichToolbarState(editor: editor).activeStyles, [.bold])
        }
    }
}
