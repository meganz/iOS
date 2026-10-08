import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. A tap into another row: UIKit sets the new selection before that row's text view
// becomes first responder. The model must follow, or the toolbar and its actions work on the old row.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichRowTapTests {
    /// Rich mode with the caret in the heading row, put there by the model.
    private func harnessInHeading() async throws -> RichListHarness {
        let harness = try RichListHarness("# A\n\nbody")
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView?.text == "A" }
        #expect(harness.model.toolbar.headingLevel == 1)
        return harness
    }

    /// Like a tap: the selection first, then the keyboard.
    private func tap(_ harness: RichListHarness, row: Int, range: NSRange) throws {
        let textView = try #require(harness.textView(row: row))
        textView.selectedRange = range
        textView.becomeFirstResponder()
    }

    @Test func tapIntoAnotherRowMovesTheModelCaret() async throws {
        let harness = try await harnessInHeading()
        defer { harness.close() }
        try tap(harness, row: 1, range: NSRange(location: 2, length: 0))
        try await harness.settle()
        #expect(harness.model.selection == .caret(position(1, 2)))
        #expect(harness.model.toolbar.headingLevel == nil)
    }

    /// The heading action after the tap changes the row the user sees the caret in, never the old row.
    @Test func headingAfterATapChangesTheTappedRow() async throws {
        let harness = try await harnessInHeading()
        defer { harness.close() }
        try tap(harness, row: 1, range: NSRange(location: 2, length: 0))
        try await harness.settle()
        harness.model.apply(.setHeading(2))
        #expect(harness.model.row(at: 0).block == heading(1, "A"))
        #expect(harness.model.row(at: 1).block == heading(2, "body"))
    }

    @Test func wordSelectionInAnotherRowReachesTheModel() async throws {
        let harness = try await harnessInHeading()
        defer { harness.close() }
        try tap(harness, row: 1, range: NSRange(location: 0, length: 4))
        try await harness.settle()
        #expect(harness.model.selection == .range(0..<4, inBlock: 1))
        harness.model.toggleStyle(.bold)
        #expect(harness.model.row(at: 0).block == heading(1, "A"))
        #expect(harness.model.row(at: 1).block == paragraph("body", (0..<4, .bold)))
    }

    /// When the model moves the focus (Enter, undo), the text view's own start caret is not reported back.
    @Test func modelFocusKeepsTheModelCaret() async throws {
        let harness = try RichListHarness("ab\n\ncd")
        defer { harness.close() }
        harness.focus(row: 1, caret: 2)
        try await harness.waitUntil { harness.focusedTextView?.text == "cd" }
        #expect(harness.model.selection == .caret(position(1, 2)))
        #expect(harness.focusedTextView?.selectedRange == NSRange(location: 2, length: 0))
    }
}
