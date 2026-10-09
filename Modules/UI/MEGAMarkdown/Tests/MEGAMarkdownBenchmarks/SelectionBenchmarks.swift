import MEGABenchmark
import MEGAMarkdown
@testable import MEGAMarkdownEditor
import QuartzCore
import SwiftUI
import UIKit
import XCTest

/// The selection over rows in a window, on a text just under the rich limit. Run with `TEST_RUNNER_MEGA_BENCH=1`.
/// Each selection test has a twin without a selection, so the cost of the selection layer shows as the difference.
@MainActor
final class SelectionBenchmarks: BenchmarkCase {
    private static let atLimit = BenchmarkDocuments.makeLargeDocument(targetBytes: RichTextLimit.maxLength - 20_000)
    /// About 11 screens of a phone.
    private static let autoscrollDistance: CGFloat = 10_000
    private static let screensToScroll = 100

    @MainActor
    private struct Editor {
        let window: UIWindow
        let adapter: RichRowAdapter
        let controller: CrossBlockSelectionController
        var list: MarkdownRowListView { adapter.list.view }
    }

    private var metrics: [any XCTMetric] {
        [XCTClockMetric(), MainThreadStallMetric(), FrameHitchMetric(), PeakFootprintMetric()]
    }

    private var manualOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        return options
    }

    // MARK: - Autoscroll

    /// A drag holds the finger at the bottom edge until the list scrolled 10,000 pt. The head follows every step.
    func testAutoscrollWithASelection() throws {
        try measureAutoscroll(withSelection: true)
    }

    /// The same scroll by the same display link, with no selection.
    func testAutoscrollWithoutASelection() throws {
        try measureAutoscroll(withSelection: false)
    }

    private func measureAutoscroll(withSelection: Bool) throws {
        var failure: (any Error)?
        measure(metrics: metrics, options: manualOptions) {
            do {
                let editor = try open()
                if withSelection { try beginDrag(in: editor) }
                let finger = bottomEdgeInWindow(of: editor.list)
                editor.controller.lastFingerInWindow = finger
                startMeasuring()
                editor.controller.autoScroller?.update(fingerInWindow: finger)
                try turnMainLoop(timeout: 60) { editor.list.contentOffset.y >= Self.autoscrollDistance }
                stopMeasuring()
                editor.controller.autoScroller?.stop()
                if withSelection {
                    XCTAssertGreaterThan(editor.controller.selection?.head.blockIndex ?? 0, 100)
                }
                close(editor)
            } catch {
                failure = error
                stopMeasuring()
            }
        }
        if let failure { throw failure }
    }

    // MARK: - Head moves

    /// 300 finger moves over the rows on screen while a drag holds a selection over rows.
    func testHeadMovesOverVisibleRows() throws {
        var failure: (any Error)?
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric()], options: manualOptions) {
            do {
                let editor = try open()
                try beginDrag(in: editor)
                let list = editor.list
                // Stay out of the edge zones, so the list does not scroll.
                let top = list.contentOffset.y + list.adjustedContentInset.top + SelectionGeometry.autoscrollZone + 10
                let bottom = list.contentOffset.y + list.bounds.height - list.adjustedContentInset.bottom - SelectionGeometry.autoscrollZone - 10
                startMeasuring()
                for step in 0..<300 {
                    let fraction = CGFloat(step % 100) / 100
                    let point = CGPoint(x: list.bounds.midX, y: top + (bottom - top) * fraction)
                    _ = editor.controller.touchMoved(to: point, inWindow: list.convert(point, to: nil), others: [])
                    if step % 10 == 0 { CATransaction.flush() }
                }
                CATransaction.flush()
                stopMeasuring()
                XCTAssertEqual(list.contentOffset.y, -list.adjustedContentInset.top, accuracy: 1)
                close(editor)
            } catch {
                failure = error
                stopMeasuring()
            }
        }
        if let failure { throw failure }
    }

    // MARK: - Select All

    /// Select All on the whole text: the model, the toolbar state, the focus move and the selection display.
    func testSelectAllShowsTheSelection() throws {
        var failure: (any Error)?
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()], options: manualOptions) {
            do {
                let editor = try open()
                startMeasuring()
                editor.controller.selectAll()
                editor.list.layoutIfNeeded()
                CATransaction.flush()
                stopMeasuring()
                XCTAssertTrue(editor.controller.isDisplayActive)
                close(editor)
            } catch {
                failure = error
                stopMeasuring()
            }
        }
        if let failure { throw failure }
    }

    /// 100 screens down while Select All is active: every new row asks the selection display for its rects.
    func testScrollWithSelectAll() throws {
        try measureScroll(selectAll: true)
    }

    /// The same 100 screens with no selection.
    func testScrollWithoutASelection() throws {
        try measureScroll(selectAll: false)
    }

    private func measureScroll(selectAll: Bool) throws {
        var failure: (any Error)?
        measure(metrics: metrics, options: manualOptions) {
            do {
                let editor = try open()
                if selectAll {
                    editor.adapter.model.selectAll()
                    try turnMainLoop(timeout: 30) { editor.controller.isDisplayActive }
                }
                let list = editor.list
                list.contentOffset.y = -list.adjustedContentInset.top
                list.layoutIfNeeded()
                startMeasuring()
                for _ in 0..<Self.screensToScroll {
                    list.contentOffset.y += list.bounds.height
                    list.layoutIfNeeded()
                    CATransaction.flush()
                    turnMainLoop(for: 0.001)
                }
                stopMeasuring()
                XCTAssertGreaterThan(list.indexPathsForVisibleItems.map(\.item).min() ?? 0, 0)
                close(editor)
            } catch {
                failure = error
                stopMeasuring()
            }
        }
        if let failure { throw failure }
    }

    // MARK: - Helpers

    private func open() throws -> Editor {
        guard case .loaded(let load) = RichEditorLoad.make(Self.atLimit) else {
            throw MainLoopError.timeout(seconds: 0)
        }
        let adapter = RichRowAdapter(model: RichEditorModel(editor: load.editor), load: load)
        let host = UIHostingController(rootView: RichEditorView(adapter: adapter, baseURL: nil))
        host.view.frame = CGRect(origin: .zero, size: PreviewCellBenchmarks.phoneSize)
        let window = PreviewCellBenchmarks.window(showing: host)
        try turnMainLoop(timeout: 30) { adapter.selectionHandler is CrossBlockSelectionController && !adapter.list.view.visibleCells.isEmpty }
        guard let controller = adapter.selectionHandler as? CrossBlockSelectionController else {
            throw MainLoopError.timeout(seconds: 30)
        }
        CATransaction.flush()
        return Editor(window: window, adapter: adapter, controller: controller)
    }

    /// A selection from the first row to the third, held by a drag, like after a takeover.
    private func beginDrag(in editor: Editor) throws {
        let model = editor.adapter.model
        model.select(RichSelection(start: RichPosition(blockIndex: 0, offset: 0), end: RichPosition(blockIndex: 2, offset: 0)))
        try turnMainLoop(timeout: 30) { editor.controller.isDisplayActive }
        editor.controller.drag = .dragging(offset: .zero)
    }

    /// A finger 5 pt above the bottom edge of the visible rows, deep in the edge zone.
    private func bottomEdgeInWindow(of list: MarkdownRowListView) -> CGPoint {
        let y = list.contentOffset.y + list.bounds.height - list.adjustedContentInset.bottom - 5
        return list.convert(CGPoint(x: list.bounds.midX, y: y), to: nil)
    }

    private func close(_ editor: Editor) {
        editor.controller.autoScroller?.stop()
        editor.controller.drag = .idle
        PreviewCellBenchmarks.close(editor.window)
    }
}
