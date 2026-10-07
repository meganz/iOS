import MEGABenchmark
@testable import MEGAMarkdownEditor
import XCTest

/// Rich editor model benchmarks at the rich mode limit (`RichTextLimit.maxLength`), with XCTest metrics.
/// They run only with `TEST_RUNNER_MEGA_BENCH=1`. Limits: `Limits.json` next to this file.
///
/// The model has no UI, so frame and main run loop metrics (`FrameHitchMetric`, `MainThreadStallMetric`) do not apply,
/// and it writes no files, so `XCTStorageMetric` has nothing to count.
final class RichEditorBenchmarks: BenchmarkCase {
    /// Just under the limit: the generator adds one more section than it needs.
    private static let atLimit = BenchmarkDocuments.makeLargeDocument(targetBytes: RichTextLimit.maxLength - 20_000)

    private var fewIterations: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        return options
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        XCTAssertTrue(RichTextLimit.allowsRichMode(Self.atLimit))
    }

    // MARK: - Load and save

    /// Open in rich mode: parse, convert, write back once and check that it parses the same.
    func testLoadAtRichLimit() {
        let expectedRows = Self.expectedRows(in: Self.atLimit)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric(), XCTMemoryMetric()]) {
            XCTAssertEqual(RichEditor(markdown: Self.atLimit).rows.count, expectedRows)
        }
    }

    /// The same load, split into its phases by the importer's signposts.
    func testLoadPhasesAtRichLimit() {
        let metrics = [RichImportSignposts.parse, RichImportSignposts.convert, RichImportSignposts.verify].map {
            XCTOSSignpostMetric(subsystem: RichImportSignposts.subsystem, category: RichImportSignposts.category, name: "\($0)")
        }
        measure(metrics: metrics) {
            XCTAssertEqual(RichMarkdownConverter.load(Self.atLimit).repairRounds, 0)
        }
    }

    /// A save with no cache: every text is written and checked.
    func testColdExportAtRichLimit() {
        let document = RichMarkdownConverter.document(from: Self.atLimit)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            XCTAssertGreaterThan(RichMarkdownConverter.markdown(from: document).utf8.count, Self.atLimit.utf8.count / 2)
        }
    }

    /// A save after one key: the cache writes only the changed text again.
    func testExportAfterOneEditAtRichLimit() {
        let loaded = RichEditor(markdown: Self.atLimit)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            var editor = loaded
            editor.replaceText(inBlock: 1, range: 0..<0, with: "x")
            XCTAssertNotNil(editor.exportChanges())
        }
    }

    // MARK: - Editing

    /// 500 keys in the middle of one 50,000 character paragraph. Divide the time by 500 for one key.
    func testTypingInALongParagraph() {
        let loaded = editor(blocks: [.paragraph(RichText(String(repeating: "word ", count: 10_000)))])
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            var editor = loaded
            for key in 0..<500 {
                editor.replaceText(inBlock: 0, range: (25_000 + key)..<(25_000 + key), with: "a")
            }
            XCTAssertEqual(editor.rows[0].block.length, 50_500)
        }
    }

    /// 100 Enters spread over the document.
    func testEnterAtRichLimit() {
        let loaded = RichEditor(markdown: Self.atLimit)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            var editor = loaded
            for step in 0..<100 {
                editor.select(.caret(RichPosition(blockIndex: step * editor.rows.count / 100, offset: 1)))
                editor.insertParagraphBreak()
            }
            XCTAssertEqual(editor.undoStack.undoSteps.count, 100)
        }
    }

    /// Backspace at block starts: removes structure or joins blocks.
    func testBackspaceAtBlockStartsAtRichLimit() {
        let loaded = RichEditor(markdown: Self.atLimit)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            var editor = loaded
            for step in 1...100 {
                editor.select(.caret(RichPosition(blockIndex: step * (editor.rows.count - 1) / 100, offset: 0)))
                editor.deleteBackward()
            }
            XCTAssertGreaterThan(editor.undoStack.undoSteps.count, 50)
        }
    }

    /// Bold over the whole document: one change to thousands of blocks.
    func testBoldAcrossTheDocumentAtRichLimit() {
        var loaded = RichEditor(markdown: Self.atLimit)
        loaded.selectAll()
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            var editor = loaded
            editor.toggleStyle(.bold)
            XCTAssertTrue(editor.activeStyles.contains(.bold))
        }
    }

    /// 100 edits, then undo all and redo all.
    func testUndoAndRedoAtRichLimit() {
        var loaded = RichEditor(markdown: Self.atLimit)
        for step in 0..<100 {
            loaded.select(.caret(RichPosition(blockIndex: step * loaded.rows.count / 100, offset: 0)))
            loaded.insertParagraphBreak()
        }
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            var editor = loaded
            while editor.canUndo { editor.undo() }
            while editor.canRedo { editor.redo() }
            XCTAssertEqual(editor.rows.count, loaded.rows.count)
        }
    }

    /// The memory that 100 undo steps keep. A step holds only the rows it replaced.
    func testUndoHistoryMemoryAtRichLimit() {
        let loaded = RichEditor(markdown: Self.atLimit)
        measure(metrics: [PeakFootprintMetric(), XCTMemoryMetric()]) {
            var editor = loaded
            for step in 0..<100 {
                editor.select(.caret(RichPosition(blockIndex: step * editor.rows.count / 100, offset: 0)))
                editor.insertText("x\ny")
            }
            XCTAssertEqual(editor.undoStack.undoSteps.count, 100)
        }
    }

    /// The toolbar's read after Select All on 167,000 rows that are all bold: the pass cannot stop early.
    func testSelectionSummaryOfManyStyledRows() {
        let rows = (0..<167_000).map { _ in RichBlock.paragraph(RichText("bold", spans: [RichSpan(range: 0..<4, style: .bold)])) }
        var loaded = editor(blocks: rows)
        loaded.selectAll()
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            XCTAssertEqual(loaded.selectionSummary.activeStyles, [.bold])
        }
    }

    // MARK: - Clipboard

    /// Select all and copy: plain text and Markdown of the whole document.
    func testCopyAllAtRichLimit() {
        var loaded = RichEditor(markdown: Self.atLimit)
        loaded.selectAll()
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            XCTAssertGreaterThan(loaded.copy()?.markdown.utf8.count ?? 0, Self.atLimit.utf8.count / 2)
        }
    }

    /// Paste a document at the limit into an empty editor: one import, one insert.
    func testPasteAtRichLimit() {
        let expectedRows = Self.expectedRows(in: Self.atLimit)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            var editor = RichEditor(newFile: RichDocument(blocks: []))
            editor.paste(RichPasteContent(markdown: Self.atLimit))
            // The text ends with a divider, so an empty paragraph follows it for the caret.
            XCTAssertEqual(editor.rows.count, expectedRows + 1)
        }
    }

    /// Cut half of the document, as select mode does: one join across thousands of blocks.
    func testCutHalfAtRichLimit() {
        let loaded = RichEditor(markdown: Self.atLimit)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            var editor = loaded
            let count = editor.rows.count
            editor.select(RichSelection(start: RichPosition(blockIndex: count / 4, offset: 0), end: RichPosition(blockIndex: 3 * count / 4, offset: 0)))
            XCTAssertNotNil(editor.cut())
            XCTAssertLessThan(editor.rows.count, count)
        }
    }

    // MARK: - Scaling

    /// Load time must grow about linearly: 2x the text takes less than 3x the time. Uses the fastest of 3 runs.
    func testLoadTimeGrowsLinearly() {
        let half = BenchmarkDocuments.makeLargeDocument(targetBytes: RichTextLimit.maxLength / 2 - 20_000)
        let small = Self.fastest { _ = RichEditor(markdown: half) }
        let large = Self.fastest { _ = RichEditor(markdown: Self.atLimit) }
        XCTAssertLessThan(large, small * 3, "half \(small), full \(large)")
    }

    // MARK: - Helpers

    private func editor(blocks: [RichBlock]) -> RichEditor {
        RichEditor(newFile: RichDocument(blocks: blocks))
    }

    /// Rows per generated section: heading, 2 paragraph rows... are counted from a one-section load.
    private static func expectedRows(in markdown: String) -> Int {
        let sections = markdown.components(separatedBy: "## Section heading").count - 1
        let one = BenchmarkDocuments.makeLargeDocument(targetBytes: 1)
        let rowsPerSection = RichMarkdownConverter.document(from: one).blocks.count
        return sections * rowsPerSection
    }

    private static func fastest(_ work: () -> Void) -> Duration {
        (0..<3).map { _ in ContinuousClock().measure(work) }.min() ?? .zero
    }
}
