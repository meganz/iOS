import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. Drags through the controller's touch entry points, the calls the list watcher makes.
// A test cannot make a real native handle drag. That part is checked by hand on the iOS 18.6 and 26.4 simulators.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct SelectionDragTests {
    private static let text = "alpha beta gamma delta\n\ndelta epsilon\n\nzeta eta theta iota kappa"

    @Test func dragInsideTheRowKeepsTheNativeSelection() async throws {
        let harness = try RichListHarness(Self.text)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        let end = try await nativeRange(harness, row: 0, range: 6..<10, caretAtEnd: true)

        controller.touchBegan(at: end, others: [])
        let taken = controller.touchMoved(to: CGPoint(x: end.x + 30, y: end.y), inWindow: .zero, others: [])

        #expect(!taken)
        #expect(controller.selection == nil)
        controller.touchEnded(at: CGPoint(x: end.x + 30, y: end.y), listPanBegan: false, cancelled: false)
    }

    @Test func nativeEndDraggedOutOfTheRowSelectsOverRowsAtLift() async throws {
        let harness = try RichListHarness(Self.text)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        let end = try await nativeRange(harness, row: 0, range: 6..<10, caretAtEnd: true)
        let pan = harness.list.view.panGestureRecognizer
        let target = try caretCenter(row: 2, offset: 9, harness)

        controller.touchBegan(at: end, others: [])
        let taken = controller.touchMoved(to: target, inWindow: harness.list.view.convert(target, to: nil), others: [pan])

        #expect(taken)
        #expect(pan.isEnabled)
        let head = try #require(controller.selection?.head)
        #expect(controller.selection?.anchor == RichPosition(blockIndex: 0, offset: 6))
        #expect(head == RichPosition(blockIndex: 2, offset: 9))
        // The model gets the selection only when the finger lifts.
        #expect(harness.model.selection == .range(6..<10, inBlock: 0))
        #expect(harness.textView(row: 0)?.selectedRange == NSRange(location: 6, length: 0))

        controller.touchEnded(at: target, listPanBegan: false, cancelled: false)

        #expect(harness.model.selection == RichSelection(start: RichPosition(blockIndex: 0, offset: 6), end: head))
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        #expect(controller.isDisplayActive)
    }

    /// The start handle goes up: the end of the native range stays as the anchor.
    @Test func nativeStartDraggedUpKeepsTheEndAsAnchor() async throws {
        let harness = try RichListHarness(Self.text)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        let start = try await nativeRange(harness, row: 1, range: 2..<5, caretAtEnd: false)
        let target = try caretCenter(row: 0, offset: 11, harness)

        controller.touchBegan(at: start, others: [])
        #expect(controller.touchMoved(to: target, inWindow: harness.list.view.convert(target, to: nil), others: []))
        controller.touchEnded(at: target, listPanBegan: false, cancelled: false)

        #expect(controller.selection?.anchor == RichPosition(blockIndex: 1, offset: 5))
        #expect(harness.model.selection == RichSelection(start: RichPosition(blockIndex: 0, offset: 11), end: RichPosition(blockIndex: 1, offset: 5)))
    }

    /// The end handle of a selection over rows is dragged above the anchor: the selection turns around.
    @Test func handleDraggedPastTheAnchorTurnsTheSelection() async throws {
        let harness = try RichListHarness(Self.text)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: RichPosition(blockIndex: 1, offset: 2), end: RichPosition(blockIndex: 2, offset: 4)))
        try await harness.waitUntil { controller.isDisplayActive }
        let endCaret = try #require(controller.caretRect(for: RichPosition(blockIndex: 2, offset: 4)))
        let grab = CGPoint(x: endCaret.midX, y: endCaret.maxY + 4)
        // The grab offset moves the head from the finger back to the caret, so the finger aims below the caret.
        let caret = try caretCenter(row: 0, offset: 6, harness)
        let target = CGPoint(x: caret.x - (endCaret.midX - grab.x), y: caret.y - (endCaret.midY - grab.y))

        controller.touchBegan(at: grab, others: [])
        #expect(controller.touchMoved(to: target, inWindow: harness.list.view.convert(target, to: nil), others: []))
        #expect(controller.selection?.anchor == RichPosition(blockIndex: 1, offset: 2))
        controller.touchEnded(at: target, listPanBegan: false, cancelled: false)

        #expect(harness.model.selection == RichSelection(start: RichPosition(blockIndex: 0, offset: 6), end: RichPosition(blockIndex: 1, offset: 2)))
    }

    /// A swipe that starts in a row with a native range, away from its handles, is a scroll, not a selection drag.
    @Test func swipeFromElsewhereInTheRowDoesNotTakeOver() async throws {
        let harness = try RichListHarness(Self.text)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        _ = try await nativeRange(harness, row: 0, range: 0..<5, caretAtEnd: true)
        let row = try #require(harness.textView(row: 0))
        let frame = row.convert(row.bounds, to: harness.list.view)
        let start = CGPoint(x: frame.maxX - 10, y: frame.midY)
        let target = try center(of: 2, harness)

        controller.touchBegan(at: start, others: [])
        let taken = controller.touchMoved(to: target, inWindow: harness.list.view.convert(target, to: nil), others: [])

        #expect(!taken)
        #expect(controller.drag == .idle)
        #expect(controller.selection == nil)
        #expect(harness.model.selection == .range(0..<5, inBlock: 0))
    }

    /// A tap inside the highlight keeps the selection and shows the edit menu, like a native selection.
    @Test func tapOnTheSelectionKeepsIt() async throws {
        let harness = try RichListHarness(Self.text)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        let range = RichSelection(start: RichPosition(blockIndex: 0, offset: 2), end: RichPosition(blockIndex: 2, offset: 4))
        harness.model.setFocused(true)
        harness.model.select(range)
        try await harness.waitUntil { controller.isDisplayActive }
        // On the text of the middle row, which is selected whole.
        let caret = try #require(controller.caretRect(for: RichPosition(blockIndex: 1, offset: 3)))
        let point = CGPoint(x: caret.midX, y: caret.midY)

        controller.touchBegan(at: point, others: [])
        controller.touchEnded(at: point, listPanBegan: false, cancelled: false)
        try await harness.settle()

        #expect(harness.model.selection == range)
        #expect(controller.selection?.range == range)
    }

    @Test func tapOutsideTheSelectionPlacesACaret() async throws {
        let harness = try RichListHarness(Self.text)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: RichPosition(blockIndex: 0, offset: 2), end: RichPosition(blockIndex: 2, offset: 4)))
        try await harness.waitUntil { controller.isDisplayActive }
        let row = try #require(harness.textView(row: 2))
        let frame = row.convert(row.bounds, to: harness.list.view)
        let point = CGPoint(x: frame.maxX - 5, y: frame.midY)

        controller.touchBegan(at: point, others: [])
        controller.touchEnded(at: point, listPanBegan: false, cancelled: false)

        try await harness.waitUntil { controller.selection == nil }
        #expect(harness.model.selection.isCaret)
        #expect(harness.model.selection.start.blockIndex == 2)
    }

    /// A touch the system cancels is never a tap.
    @Test func cancelledTouchKeepsTheSelection() async throws {
        let harness = try RichListHarness(Self.text)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        let range = RichSelection(start: RichPosition(blockIndex: 0, offset: 2), end: RichPosition(blockIndex: 2, offset: 4))
        harness.model.setFocused(true)
        harness.model.select(range)
        try await harness.waitUntil { controller.isDisplayActive }
        let row = try #require(harness.textView(row: 2))
        let frame = row.convert(row.bounds, to: harness.list.view)
        let point = CGPoint(x: frame.maxX - 5, y: frame.midY)

        controller.touchBegan(at: point, others: [])
        controller.touchEnded(at: point, listPanBegan: false, cancelled: true)
        try await harness.settle()

        #expect(harness.model.selection == range)
    }

    /// The system cancels the touch during a handle drag. The drag still hands its selection to the model.
    @Test func cancelledDragHandsItsSelectionToTheModel() async throws {
        let harness = try RichListHarness(Self.text)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: RichPosition(blockIndex: 0, offset: 2), end: RichPosition(blockIndex: 1, offset: 4)))
        try await harness.waitUntil { controller.isDisplayActive }
        let endCaret = try #require(controller.caretRect(for: RichPosition(blockIndex: 1, offset: 4)))
        let grab = CGPoint(x: endCaret.midX, y: endCaret.midY)
        let target = try caretCenter(row: 2, offset: 4, harness)

        controller.touchBegan(at: grab, others: [])
        #expect(controller.touchMoved(to: target, inWindow: harness.list.view.convert(target, to: nil), others: []))
        controller.touchEnded(at: target, listPanBegan: false, cancelled: true)

        #expect(controller.drag == .idle)
        #expect(harness.model.selection == RichSelection(start: RichPosition(blockIndex: 0, offset: 2), end: RichPosition(blockIndex: 2, offset: 4)))
    }

    /// A tap below the middle of a divider outside the selection: the controller puts the caret after the divider.
    /// A test cannot run the row's own SwiftUI tap, so this checks only the controller's part.
    @Test func tapOnADividerOutsideTheSelectionPlacesTheCaretAfterIt() async throws {
        let harness = try RichListHarness("alpha\n\nbeta\n\n---\n\ngamma")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: RichPosition(blockIndex: 0, offset: 1), end: RichPosition(blockIndex: 1, offset: 2)))
        try await harness.waitUntil { controller.isDisplayActive }
        let divider = harness.list.itemFrame(at: harness.adapter.items(forRow: 2).lowerBound)
        let point = CGPoint(x: divider.midX, y: divider.midY + 2)

        controller.touchBegan(at: point, others: [])
        controller.touchEnded(at: point, listPanBegan: false, cancelled: false)

        try await harness.waitUntil { harness.model.selection != RichSelection(start: RichPosition(blockIndex: 0, offset: 1), end: RichPosition(blockIndex: 1, offset: 2)) }
        #expect(harness.model.selection == .caret(RichPosition(blockIndex: 2, offset: 1)))
    }

    /// A handle held at the bottom edge starts the autoscroll. After a scroll step the head is the row under the finger.
    @Test func handleAtTheBottomEdgeAutoscrolls() async throws {
        let long = (0..<80).map { "Paragraph \($0)" }.joined(separator: "\n\n")
        let harness = try RichListHarness(long, height: 400)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: RichPosition(blockIndex: 0, offset: 2), end: RichPosition(blockIndex: 1, offset: 4)))
        try await harness.waitUntil { controller.isDisplayActive }
        let endCaret = try #require(controller.caretRect(for: RichPosition(blockIndex: 1, offset: 4)))
        let grab = CGPoint(x: endCaret.midX, y: endCaret.midY)
        let list = harness.list.view
        let bottom = CGPoint(x: grab.x, y: list.contentOffset.y + list.bounds.height - list.adjustedContentInset.bottom - 5)

        controller.touchBegan(at: grab, others: [])
        #expect(controller.touchMoved(to: bottom, inWindow: list.convert(bottom, to: nil), others: []))
        #expect(controller.autoScroller?.isScrolling == true)
        // One scroll step by hand, so the result does not depend on display timing.
        controller.autoScroller?.stop()
        list.contentOffset.y += 600
        list.layoutIfNeeded()
        controller.autoscrolled()
        let finger = CGPoint(x: bottom.x, y: bottom.y + 600)
        let row = try #require(harness.list.item(at: finger).map { harness.adapter.row(forItem: $0).row })
        controller.touchEnded(at: finger, listPanBegan: false, cancelled: false)

        #expect(row > 10)
        #expect(harness.model.selection.start == RichPosition(blockIndex: 0, offset: 2))
        #expect(harness.model.selection.end.blockIndex == row)
    }

    /// A scroll is not a tap: the selection stays, also after the list moved two screens.
    @Test func scrollKeepsTheSelection() async throws {
        let long = (0..<80).map { "Paragraph \($0)" }.joined(separator: "\n\n")
        let harness = try RichListHarness(long, height: 400)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        let range = RichSelection(start: RichPosition(blockIndex: 1, offset: 2), end: RichPosition(blockIndex: 3, offset: 4))
        harness.model.setFocused(true)
        harness.model.select(range)
        try await harness.waitUntil { controller.isDisplayActive }
        let start = try center(of: 2, harness)

        controller.touchBegan(at: start, others: [])
        harness.list.view.contentOffset.y += 800
        try await harness.settle()
        controller.touchEnded(at: CGPoint(x: start.x, y: start.y - 300), listPanBegan: true, cancelled: false)
        try await harness.settle()

        #expect(harness.model.selection == range)
        #expect(controller.selection?.range == range)
        #expect(controller.isDisplayActive)
    }

    // MARK: - Helpers

    /// Focuses a range in a text row and returns its start or end caret center in the list view.
    private func nativeRange(_ harness: RichListHarness, row: Int, range: Range<Int>, caretAtEnd: Bool) async throws -> CGPoint {
        harness.model.setFocused(true)
        harness.model.select(.range(range, inBlock: row))
        try await harness.waitUntil {
            harness.focusedTextView === harness.textView(row: row) && harness.focusedTextView?.selectedRange.length == range.count
        }
        let textView = try #require(harness.focusedTextView)
        let selected = try #require(textView.selectedTextRange)
        let caret = textView.caretRect(for: caretAtEnd ? selected.end : selected.start)
        let rect = textView.convert(caret, to: harness.list.view)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    /// The center of the caret at `offset` in a text row, in the list view.
    private func caretCenter(row: Int, offset: Int, _ harness: RichListHarness) throws -> CGPoint {
        let textView = try #require(harness.textView(row: row))
        let position = try #require(textView.position(from: textView.beginningOfDocument, offset: offset))
        let rect = textView.convert(textView.caretRect(for: position), to: harness.list.view)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    private func center(of row: Int, _ harness: RichListHarness) throws -> CGPoint {
        let textView = try #require(harness.textView(row: row))
        let frame = textView.convert(textView.bounds, to: harness.list.view)
        return CGPoint(x: frame.midX, y: frame.midY)
    }
}
