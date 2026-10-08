import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. A checkbox tap must not move the caret or scroll to it.
// Leaving the editor must drop the keyboard for good.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichFocusLayoutTests {
    private static var tasks: String {
        (0..<40).map { "- [ ] task \($0)" }.joined(separator: "\n")
    }

    /// The tap does not move the selection. So the list must not scroll back to the caret.
    @Test func checkboxTapFarFromTheCaretDoesNotScrollOrMoveTheCaret() async throws {
        let harness = try RichListHarness(Self.tasks, height: 500)
        defer { harness.close() }
        harness.focus(row: 0, caret: 2)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let view = harness.list.view
        view.setContentOffset(CGPoint(x: 0, y: 700), animated: false)
        try await harness.settle(150)
        let offset = view.contentOffset.y
        let selection = harness.model.selection
        let row = try #require(view.indexPathsForVisibleItems.map { harness.adapter.row(forItem: $0.item).row }.max())
        #expect(row > 5)

        harness.model.toggleCheckbox(inRow: row)
        try await harness.settle(150)

        #expect(harness.model.row(at: row).block.listItem?.isChecked == true, "the checkbox did not change")
        #expect(view.contentOffset.y == offset, "offset \(offset) became \(view.contentOffset.y)")
        #expect(harness.model.selection == selection)
    }

    /// The editor leaves the screen. SwiftUI removes its rows in any order, so none may take the keyboard back.
    @Test func leavingTheEditorDropsTheKeyboardForGood() async throws {
        let editor = EditorWindow("Paragraph\n\n- item", mode: .rich)
        defer { editor.close() }
        let textView = try await editor.waitForRichRow("Paragraph")
        editor.typeAtEnd("x", into: textView)
        try await EditorWindow.settle()
        #expect(textView.isFirstResponder)

        editor.model.isShown = false
        try await EditorWindow.settle(300)

        #expect(!textView.isFirstResponder, "the removed row keeps the keyboard")
        #expect(textView.window == nil)
    }

    private static let emptyItemRow = 20

    private static var itemsWithOneEmpty: String {
        (0..<40).map { $0 == emptyItemRow ? "-" : "- item \($0)" }.joined(separator: "\n")
    }

    /// Enter in an empty list item turns the row into a paragraph in place. The text view is replaced.
    /// The keyboard stays and the list does not scroll.
    @Test func enterInAnEmptyItemKeepsTheKeyboardAndTheOffset() async throws {
        let harness = try RichListHarness(Self.itemsWithOneEmpty, height: 500)
        defer { harness.close() }
        try await measureAllRows(harness)
        harness.focus(row: Self.emptyItemRow, caret: 0)
        try await harness.waitUntil { harness.focusedTextView != nil }
        try await harness.settle(100)
        let view = harness.list.view
        let offset = view.contentOffset.y
        let bottomInset = view.contentInset.bottom
        #expect(offset > 0, "the list did not scroll to the caret")
        let item = harness.adapter.items(forRow: Self.emptyItemRow).lowerBound
        let rowTop = view.convert(harness.list.itemFrame(at: item), to: nil).minY

        try harness.type("\n")
        // Sample the focus on every turn, so a short gap shows.
        for _ in 0..<20 {
            try await Task.sleep(for: .milliseconds(15))
            #expect(harness.adapter.responder.isFirstResponder || harness.focusedTextView != nil, "the keyboard went away")
        }
        try await harness.settle(100)
        #expect(harness.model.row(at: Self.emptyItemRow).block.listItem == nil, "the row is still a list item")
        // The list now ends above the row, so a block gap opens above it and pushes it down.
        // The offset stays, so the rows above do not move.
        let rowTopAfter = view.convert(harness.list.itemFrame(at: item), to: nil).minY
        let gap = MarkdownTheme.default.blockSpacing
        #expect(abs(rowTopAfter - (rowTop + gap)) < 1, "row top \(rowTop) became \(rowTopAfter), expected a gap of \(gap)")
        #expect(view.contentOffset.y == offset, "offset \(offset) became \(view.contentOffset.y)")
        #expect(view.contentInset.bottom == bottomInset)
        #expect(harness.focusedTextView != nil, "no row has the focus after the edit")
    }

    /// Rows far from the screen have an estimated height until the list shows them. Showing them all first
    /// keeps a later change of an estimate out of the offset.
    private func measureAllRows(_ harness: RichListHarness) async throws {
        let view = harness.list.view
        var y: CGFloat = 0
        while y < view.contentSize.height {
            view.setContentOffset(CGPoint(x: 0, y: y), animated: false)
            try await harness.settle(30)
            y += view.bounds.height / 2
        }
        view.setContentOffset(.zero, animated: false)
        try await harness.settle(50)
    }
}
