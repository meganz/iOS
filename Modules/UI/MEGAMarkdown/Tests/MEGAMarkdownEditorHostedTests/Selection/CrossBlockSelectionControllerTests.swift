import MEGAMarkdown
@testable import MEGAMarkdownEditor
import SwiftUI
import Testing
import UIKit

// Needs the iOS simulator. A selection over rows in a window: highlight, handles and ⇧ with arrows.
// Checked on iOS 18.6 and 26.4 simulators only; iOS 17 is not checked.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct CrossBlockSelectionControllerTests {
    @Test func shiftDownAtTheLastLineSelectsIntoTheNextRow() async throws {
        let harness = try RichListHarness("abc\n\ndef\n\nghi")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }

        controller.extendSelection(fromRow: 0, through: .down)

        #expect(harness.model.selection == RichSelection(start: position(0, 1), end: position(1, 3)))
        #expect(controller.selection == CrossBlockSelection(anchor: position(0, 1), head: position(1, 3)))
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        #expect(controller.isDisplayActive)
        #expect(harness.list.pinnedItem == nil)
    }

    @Test func shiftUpAfterShiftDownGoesBackIntoOneRow() async throws {
        let harness = try RichListHarness("abc\n\ndef\n\nghi")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        controller.extendSelection(fromRow: 0, through: .down)
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }

        controller.extendSelection(fromRow: 1, through: .up)

        #expect(harness.model.selection == RichSelection(start: position(0, 1), end: position(0, 3)))
        #expect(controller.selection == nil)
        #expect(!controller.isDisplayActive)
        try await harness.waitUntil { harness.focusedTextView === harness.textView(row: 0) }
        #expect(harness.focusedTextView?.selectedRange == NSRange(location: 1, length: 2))
    }

    /// The head walks up past the anchor: the selection turns around and the anchor stays.
    @Test func shiftUpPastTheAnchorTurnsTheSelection() async throws {
        let harness = try RichListHarness("abc\n\ndef\n\nghi")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.focus(row: 1, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }

        controller.extendSelection(fromRow: 1, through: .up)

        #expect(controller.selection == CrossBlockSelection(anchor: position(1, 1), head: position(0, 0)))
        #expect(harness.model.selection == RichSelection(start: position(0, 0), end: position(1, 1)))
    }

    /// SwiftUI can attach the controller of a new list view before it detaches the old one. The new hooks stay.
    @Test func detachKeepsTheHooksOfANewerController() async throws {
        let harness = try RichListHarness("abc\n\ndef")
        defer { harness.close() }
        let first = try #require(harness.selectionController)
        let second = CrossBlockSelectionController(adapter: harness.adapter)
        second.attach()

        first.detach()

        #expect(harness.adapter.selectionHandler === second)
        #expect(harness.adapter.onLayout != nil)
        second.detach()
        #expect(harness.adapter.selectionHandler == nil)
        #expect(harness.adapter.onLayout == nil)
    }

    /// Select All from a row (its edit menu or ⌘A) goes to the selection layer: the whole document and both handles.
    @Test func selectAllShowsTheHandlesAtBothEnds() async throws {
        let harness = try RichListHarness("abc\n\n---\n\nghi")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }

        harness.focusedTextView?.selectAll(nil)

        #expect(harness.model.selection == RichSelection(start: position(0, 0), end: position(2, 3)))
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        #expect(controller.isDisplayActive)
        let start = try #require(controller.caretRect(for: position(0, 0)))
        let end = try #require(controller.caretRect(for: position(2, 3)))
        let rects = controller.selectionRects(for: harness.model.selection)
        // A highlight rect has no caret width, so the handle rects match the carets within 2 pt.
        let startRects = rects.filter(\.containsStart).map(\.rect)
        let endRects = rects.filter(\.containsEnd).map(\.rect)
        #expect(startRects.count == 1)
        #expect(endRects.count == 1)
        #expect(abs((startRects.first?.minX ?? -100) - start.minX) <= 2)
        #expect(startRects.first?.minY == start.minY)
        #expect(abs((endRects.first?.maxX ?? -100) - end.maxX) <= 2)
        #expect(endRects.first?.minY == end.minY)
        // The divider row in the middle is covered by one rect, from its top, without the gap below it.
        let divider = harness.list.itemFrame(at: harness.adapter.items(forRow: 1).lowerBound)
        let onDivider = rects.filter { $0.rect.width > 0 && $0.rect.minY >= divider.minY && $0.rect.maxY <= divider.maxY }
        #expect(onDivider.count == 1)
        #expect(onDivider.first?.rect.minY == divider.minY)
        #expect((onDivider.first?.rect.height ?? 0) < divider.height)
        #expect(controller.handleViews.count == 2)
    }

    /// A tap selects a divider whole. The layer highlights it alone, without the gap below it.
    @Test func singleSelectedDividerIsHighlighted() async throws {
        let harness = try RichListHarness("abc\n\n---\n\ndef")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)

        harness.adapter.selectAtomic(row: 1)
        try await harness.waitUntil { controller.isDisplayActive }

        let range = RichSelection.range(0..<1, inBlock: 1)
        #expect(controller.selection?.range == range)
        let divider = harness.list.itemFrame(at: harness.adapter.items(forRow: 1).lowerBound)
        let rects = controller.selectionRects(for: range).filter { $0.rect.width > 0 }
        #expect(rects.count == 1)
        #expect(rects.first?.rect.minY == divider.minY)
        #expect((rects.first?.rect.height ?? 0) < divider.height)
        #expect(rects.first?.containsStart == true)
        #expect(rects.first?.containsEnd == true)
    }

    /// The last row has no gap below, so its item is just the drawn divider. A divider in the middle, without its gap,
    /// must be as tall: this pins that the trimmed gap is the gap the row draws.
    @Test func dividerHighlightEndsAtTheDrawnDivider() async throws {
        let harness = try RichListHarness("---\n\ntext\n\n---")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.selectAll()
        try await harness.waitUntil { controller.isDisplayActive }

        let first = harness.list.itemFrame(at: harness.adapter.items(forRow: 0).lowerBound)
        let last = harness.list.itemFrame(at: harness.adapter.items(forRow: 2).lowerBound)
        let rects = controller.selectionRects(for: harness.model.selection).filter { $0.rect.width > 0 }
        let firstRect = try #require(rects.first { $0.rect.minY == first.minY })
        #expect(abs(firstRect.rect.maxY - (first.minY + last.height)) < 0.5)
        #expect(harness.adapter.chrome[2].gapBelow == .none)
    }

    /// Undo puts back a selection over rows. The layer shows it again with both handles.
    @Test func undoOfACutOverRowsShowsTheSelectionAgain() async throws {
        let harness = try RichListHarness("abc\n\ndef\n\nghi\n\njkl")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        let range = RichSelection(start: position(0, 1), end: position(2, 2))
        harness.model.select(range)
        _ = harness.model.cut()
        try await harness.settle()
        #expect(controller.selection == nil)

        harness.model.undo()
        try await harness.waitUntil { controller.isDisplayActive }

        #expect(harness.model.selection == range)
        #expect(controller.selection == CrossBlockSelection(anchor: range.start, head: range.end))
        let rects = controller.selectionRects(for: range)
        #expect(rects.filter(\.containsStart).count == 1)
        #expect(rects.filter(\.containsEnd).count == 1)
        #expect(controller.handleViews.count == 2)
    }

    /// A tap or a key puts the caret in one row: the layer clears and the row's text view shows it.
    @Test func selectionInOneRowClearsTheLayer() async throws {
        let harness = try RichListHarness("abc\n\ndef")
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: position(0, 1), end: position(1, 2)))
        try await harness.waitUntil { controller.isDisplayActive }

        harness.model.select(.caret(position(1, 1)))

        #expect(controller.selection == nil)
        #expect(!controller.isDisplayActive)
        try await harness.waitUntil { harness.focusedTextView === harness.textView(row: 1) }
    }

    /// The end row is far below the screen. Its handle still gets a rect, at the end of that row's stored frame.
    @Test func endOffScreenGetsItsHandleRectAtTheStoredFrame() async throws {
        let text = (0..<60).map { "Paragraph \($0)" }.joined(separator: "\n\n")
        let harness = try RichListHarness(text, height: 300)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        let last = harness.model.rowCount - 1
        let range = RichSelection(start: position(0, 0), end: position(last, harness.model.row(at: last).block.length))
        harness.model.select(range)
        try await harness.settle()

        let rects = controller.selectionRects(for: range)
        let ends = rects.filter(\.containsEnd).map(\.rect)
        #expect(ends.count == 1)
        let lastFrame = harness.list.itemFrame(at: harness.adapter.items(forRow: last).lowerBound)
        #expect(ends.first?.maxY == lastFrame.maxY)
        #expect(rects.filter(\.containsStart).count == 1)
    }

    @Test func rightToLeftRowsPutTheStartHandleOnTheRight() async throws {
        let harness = try RichListHarness("שלום עולם\n\nמה שלומך", layoutDirection: .rightToLeft)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: position(0, 2), end: position(1, 3)))
        try await harness.settle()

        let rects = controller.selectionRects(for: harness.model.selection)
        let startRects = rects.filter(\.containsStart)
        let endRects = rects.filter(\.containsEnd)
        let startRect = try #require(startRects.first)
        let endRect = try #require(endRects.first)
        #expect(startRect.writingDirection == .rightToLeft)
        #expect(endRect.writingDirection == .rightToLeft)
        let row = try #require(harness.textView(row: 0))
        let rowFrame = row.convert(row.bounds, to: harness.list.view)
        let startCaret = try #require(controller.caretRect(for: position(0, 2)))
        // Two letters from the start of a right-to-left line: near its right edge.
        #expect(startCaret.midX > rowFrame.midX)
    }

    /// A row that starts with a Latin word runs left to right, even in a right-to-left layout.
    /// TextKit picks the paragraph direction from the first strong letter, and the rects follow it.
    @Test func rowStartingWithLatinRunsLeftToRightInARightToLeftLayout() async throws {
        let harness = try RichListHarness("iOS שלום\n\nמה שלומך", layoutDirection: .rightToLeft)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.model.select(RichSelection(start: position(0, 1), end: position(1, 2)))
        try await harness.settle()

        let rects = controller.selectionRects(for: harness.model.selection)
        let startRects = rects.filter(\.containsStart)
        let endRects = rects.filter(\.containsEnd)
        #expect(startRects.first?.writingDirection == .leftToRight)
        #expect(endRects.first?.writingDirection == .rightToLeft)
    }
}
