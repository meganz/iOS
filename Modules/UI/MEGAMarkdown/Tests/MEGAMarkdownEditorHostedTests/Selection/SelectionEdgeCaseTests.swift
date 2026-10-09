import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. Edge cases of the selection over rows: where the list scrolls, which touches the layer takes,
// where the edit menu points, a content change during a drag, and the handles of a raw block split into pages.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct SelectionEdgeCaseTests {
    private static let paragraphs = (0..<100).map { "Paragraph \($0)." }.joined(separator: "\n\n")
    private static let table = "| a | b |\n|---|---|\n" + (0..<120).map { "| \($0) | value |" }.joined(separator: "\n")

    // MARK: - Scroll after a change of the selection

    /// The start handle goes up past one screen while the list scrolls under the finger.
    /// At lift the list stays where the finger is. It does not jump back to the anchor.
    @Test func backwardDragKeepsTheHeadOnScreenAfterLift() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 400)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: position(78, 0), end: position(80, 4)))
        try await harness.waitUntil { controller.isDisplayActive }
        try await harness.settle()
        let startCaret = try #require(controller.caretRect(for: position(78, 0)))
        controller.touchBegan(at: CGPoint(x: startCaret.midX, y: startCaret.minY - 4), others: [])
        let middle = CGPoint(x: 150, y: viewport(harness).midY)
        #expect(controller.touchMoved(to: middle, inWindow: harness.list.view.convert(middle, to: nil), others: []))
        // The list scrolls as autoscroll does, until row 5 is under the finger.
        let target = rowFrame(harness, 5)
        harness.list.view.contentOffset.y = target.midY - harness.list.view.bounds.height / 2
        harness.list.view.layoutIfNeeded()
        let finger = CGPoint(x: 150, y: target.midY)
        #expect(controller.touchMoved(to: finger, inWindow: harness.list.view.convert(finger, to: nil), others: []))

        controller.touchEnded(at: finger, listPanBegan: false, cancelled: false)
        try await harness.settle(200)

        #expect(harness.model.selection.start.blockIndex == 5)
        #expect(harness.model.selection.end == position(80, 4))
        #expect(viewport(harness).intersects(rowFrame(harness, 5)))
        #expect(!viewport(harness).intersects(rowFrame(harness, 80)))
    }

    /// ⇧↑ grows the selection up past the top of the screen. The list follows the head, not the anchor.
    @Test func shiftUpPastTheScreenShowsTheHead() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 400)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.focus(row: 50, caret: 0)
        try await harness.waitUntil { harness.focusedTextView === harness.textView(row: 50) }

        for _ in 0..<15 {
            controller.extendSelection(fromRow: controller.selection?.head.blockIndex ?? 50, through: .up)
            try await harness.settle(30)
        }

        #expect(controller.selection?.head == position(35, 0))
        #expect(harness.model.selection == RichSelection(start: position(35, 0), end: position(50, 0)))
        #expect(viewport(harness).intersects(rowFrame(harness, 35)))
    }

    // MARK: - Native start handle

    /// The knob of the start handle sits above the caret, so a touch on it can be over the row above.
    /// The layer still takes that touch as a grab of the start handle.
    @Test func nativeStartKnobOverTheRowAboveIsAGrab() async throws {
        let harness = try RichListHarness("Previous paragraph.\n\nSelected word here.\n\nNext paragraph.")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(.range(0..<8, inBlock: 1))
        try await harness.waitUntil { harness.focusedTextView === harness.textView(row: 1) && harness.focusedTextView?.selectedRange.length == 8 }
        try await harness.settle()
        let textView = try #require(harness.focusedTextView)
        let range = try #require(textView.selectedTextRange)
        let caret = textView.convert(textView.caretRect(for: range.start), to: harness.list.view)
        let knob = CGPoint(x: caret.midX, y: caret.minY - 6)
        try #require(harness.list.item(at: knob) == harness.adapter.items(forRow: 0).lowerBound)

        controller.touchBegan(at: knob, others: [])

        let item = harness.adapter.items(forRow: 1).lowerBound
        #expect(controller.drag == .native(item: item, row: 1, range: NSRange(location: 0, length: 8), grabsEnd: false))
        controller.touchEnded(at: knob, listPanBegan: false, cancelled: true)
    }

    // MARK: - Edit menu place

    /// After a forward drag past one screen only the end of the selection is on screen.
    /// The menu points at the part on screen, not at the off-screen start.
    @Test func menuBoundsStayOnScreenWhenTheStartIsFarAbove() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 400)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: position(5, 2), end: position(80, 4)))
        try await harness.waitUntil { controller.isDisplayActive }
        try await harness.settle()
        try #require(viewport(harness).intersects(rowFrame(harness, 80)))

        let bounds = try #require(controller.visibleSelectionBounds())

        #expect(harness.list.view.bounds.contains(bounds))
        #expect(bounds.maxY >= rowFrame(harness, 80).minY)
    }

    // MARK: - Content change during a drag

    /// ⌘X during a handle drag removes the rows the drag names. The drag ends, and the lift keeps the model's caret.
    @Test func cutDuringAHandleDragEndsTheDrag() async throws {
        let source = (0..<10).map { "Paragraph \($0)." }.joined(separator: "\n\n")
        let harness = try RichListHarness(source)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: position(2, 0), end: position(9, 4)))
        try await harness.waitUntil { controller.isDisplayActive }
        let endCaret = try #require(controller.caretRect(for: position(9, 4)))
        let grab = CGPoint(x: endCaret.midX, y: endCaret.maxY + 4)
        controller.touchBegan(at: grab, others: [])
        let target = CGPoint(x: 150, y: rowFrame(harness, 8).midY)
        #expect(controller.touchMoved(to: target, inWindow: harness.list.view.convert(target, to: nil), others: []))

        _ = harness.model.cut()
        try await harness.settle()

        let afterCut = harness.model.selection
        #expect(afterCut == .caret(position(2, 0)))
        #expect(controller.drag == .idle)
        #expect(controller.selection == nil)
        let farther = CGPoint(x: 150, y: rowFrame(harness, 0).midY)
        #expect(!controller.touchMoved(to: farther, inWindow: harness.list.view.convert(farther, to: nil), others: []))
        controller.touchEnded(at: farther, listPanBegan: false, cancelled: false)
        try await harness.settle()
        #expect(harness.model.selection == afterCut)
    }

    /// The takeover of a native handle drag leaves a caret in the text view. A text change ends the drag,
    /// and the text view shows the model's range again.
    @Test func textChangeDuringANativeHandleDragRestoresTheRowRange() async throws {
        let harness = try RichListHarness("alpha beta gamma\n\ndelta\n\nepsilon zeta")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(.range(6..<10, inBlock: 0))
        try await harness.waitUntil { harness.focusedTextView?.selectedRange == NSRange(location: 6, length: 4) }
        let textView = try #require(harness.focusedTextView)
        let selected = try #require(textView.selectedTextRange)
        let endCaret = textView.convert(textView.caretRect(for: selected.end), to: harness.list.view)
        controller.touchBegan(at: CGPoint(x: endCaret.midX, y: endCaret.midY), others: [])
        let target = CGPoint(x: 150, y: rowFrame(harness, 2).midY)
        #expect(controller.touchMoved(to: target, inWindow: harness.list.view.convert(target, to: nil), others: []))
        #expect(harness.textView(row: 0)?.selectedRange == NSRange(location: 6, length: 0))

        harness.model.toggleStyle(.bold)
        try await harness.settle()

        #expect(harness.model.selection == .range(6..<10, inBlock: 0))
        #expect(controller.drag == .idle)
        #expect(harness.textView(row: 0)?.selectedRange == NSRange(location: 6, length: 4))
        controller.touchEnded(at: target, listPanBegan: false, cancelled: false)
    }

    // MARK: - Raw block split into pages

    /// The selection ends before a table of three pages, so the end handle belongs at the top of the first page.
    @Test func endBeforeASplitTableStandsAtItsFirstPage() async throws {
        let harness = try RichListHarness("Before.\n\n" + Self.table + "\n\nAfter.", height: 500)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        let items = harness.adapter.items(forRow: 1)
        try #require(items.count == 3)
        let range = RichSelection(start: position(0, 1), end: position(1, 0))
        harness.model.setFocused(true)
        harness.model.select(range)
        try await harness.waitUntil { controller.isDisplayActive }
        try await harness.settle()

        let ends = controller.selectionRects(for: range).filter(\.containsEnd)

        let firstPage = harness.list.itemFrame(at: items.lowerBound)
        #expect(ends.count == 1)
        #expect(ends.first?.rect.minY == firstPage.minY)
    }

    /// The selection starts after a table of three pages while only its middle page is on screen.
    /// The start handle belongs at the bottom of the last page, off screen.
    @Test func startAfterASplitTableStandsAtItsLastPage() async throws {
        let harness = try RichListHarness("Before.\n\n" + Self.table + "\n\nAfter.", height: 500)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        let items = harness.adapter.items(forRow: 1)
        try #require(items.count == 3)
        let range = RichSelection(start: position(1, 1), end: position(2, 3))
        harness.list.view.contentOffset.y = harness.list.itemFrame(at: items.lowerBound + 1).minY + 100
        harness.list.view.layoutIfNeeded()
        try #require(!viewport(harness).intersects(harness.list.itemFrame(at: items.lowerBound)))
        try #require(!viewport(harness).intersects(harness.list.itemFrame(at: items.upperBound - 1)))

        let starts = controller.selectionRects(for: range).filter(\.containsStart)

        let lastPage = harness.list.itemFrame(at: items.upperBound - 1)
        #expect(starts.count == 1)
        let start = try #require(starts.first?.rect)
        #expect(start.minY > lastPage.minY)
        #expect(start.maxY <= lastPage.maxY)
    }

    // MARK: - Helpers

    private func viewport(_ harness: RichListHarness) -> CGRect {
        harness.list.view.bounds.inset(by: harness.list.view.adjustedContentInset)
    }

    private func rowFrame(_ harness: RichListHarness, _ row: Int) -> CGRect {
        harness.list.itemFrame(at: harness.adapter.items(forRow: row).lowerBound)
    }
}
