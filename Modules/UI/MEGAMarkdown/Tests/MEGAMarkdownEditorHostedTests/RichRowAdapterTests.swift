import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. Rich mode in a window: typing, Enter, Backspace and undo move the focus between rows.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichRowAdapterTests {
    private static let paragraphs = (0..<80).map { "Paragraph \($0) with some words." }.joined(separator: "\n\n")

    /// A key is an own edit: the list is not updated, the row keeps its text view and the keyboard.
    @Test func typingKeepsTheTextViewAndTheFocus() async throws {
        let harness = try RichListHarness("abc\n\ndef")
        defer { harness.close() }
        harness.focus(row: 1, caret: 3)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textView = try #require(harness.focusedTextView)
        try harness.type("x")
        try await harness.settle()
        #expect(harness.model.row(at: 1).block == paragraph("defx"))
        #expect(harness.adapter.appliedVersion == harness.model.version)
        #expect(harness.focusedTextView === textView)
        #expect(textView.text == "defx")
        #expect(harness.list.pinnedItem == 1)
    }

    @Test func enterMovesTheFocusToTheNewRow() async throws {
        let harness = try RichListHarness("abcd\n\nnext")
        defer { harness.close() }
        harness.focus(row: 0, caret: 2)
        try await harness.waitUntil { harness.focusedTextView != nil }
        try harness.type("\n")
        try await harness.waitUntil { harness.focusedTextView?.text == "cd" }
        #expect(harness.textView(row: 0)?.text == "ab")
        #expect(harness.focusedTextView?.selectedRange == NSRange(location: 0, length: 0))
        #expect(harness.list.itemCount == 3)
        #expect(harness.list.pinnedItem == 1)
    }

    /// Enter on the last row on screen: the new row is below the visible area, and it still gets the keyboard.
    @Test func enterAtTheBottomEdgeScrollsToTheNewRow() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 400)
        defer { harness.close() }
        let lastVisible = try #require(harness.list.view.indexPathsForVisibleItems.map(\.item).max())
        harness.focus(row: lastVisible, caret: harness.model.row(at: lastVisible).block.length)
        try await harness.waitUntil { harness.focusedTextView != nil }
        try harness.type("\n")
        try await harness.waitUntil { harness.focusedTextView?.text == "" }
        let textView = try #require(harness.focusedTextView)
        let frame = textView.convert(textView.bounds, to: harness.list.view)
        #expect(harness.list.view.bounds.intersects(frame))
    }

    /// A cell that took a key holds the model version of that key. After it is reused, it must still take the new row's text.
    @Test func scrollingAfterTypingShowsEachRowItsOwnText() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 400)
        defer { harness.close() }
        harness.focus(row: 1, caret: 0)
        try await harness.waitUntil { harness.focusedTextView != nil }
        try harness.type("x")
        harness.window.endEditing(true)
        try await harness.settle()
        try await scrollDownAndCheckText(harness)
    }

    private func scrollDownAndCheckText(_ harness: RichListHarness) async throws {
        let view = harness.list.view
        for step in 1...3 {
            view.setContentOffset(CGPoint(x: 0, y: CGFloat(step) * 700), animated: false)
            try await harness.settle(100)
            let visible = view.indexPathsForVisibleItems.map(\.item)
            #expect(visible.max() ?? 0 >= step * 5, "the list did not scroll")
            for item in visible {
                let row = harness.adapter.row(forItem: item).row
                let textView = try #require(harness.adapter.textView(forItem: item))
                #expect(textView.text == harness.model.row(at: row).block.richText?.text)
            }
        }
    }

    @Test func backspaceAtTheStartJoinsAndKeepsTheCaret() async throws {
        let harness = try RichListHarness("ab\n\ncd")
        defer { harness.close() }
        harness.focus(row: 1, caret: 0)
        try await harness.waitUntil { harness.focusedTextView?.text == "cd" }
        harness.focusedTextView?.deleteBackward()
        try await harness.waitUntil { harness.focusedTextView?.text == "abcd" }
        #expect(harness.model.rowCount == 1)
        #expect(harness.focusedTextView?.selectedRange == NSRange(location: 2, length: 0))
    }

    @Test func undoPutsBackTheTextAndTheCaret() async throws {
        let harness = try RichListHarness("abcd")
        defer { harness.close() }
        harness.focus(row: 0, caret: 2)
        try await harness.waitUntil { harness.focusedTextView != nil }
        try harness.type("\n")
        try await harness.waitUntil { harness.focusedTextView?.text == "cd" }
        harness.focusedTextView?.undoManager?.undo()
        try await harness.waitUntil { harness.focusedTextView?.text == "abcd" }
        #expect(harness.model.rowCount == 1)
        #expect(harness.list.itemCount == 1)
        #expect(harness.focusedTextView?.selectedRange == NSRange(location: 2, length: 0))
    }

    /// The focused row stays in the list 20 screens away, so its text view keeps the keyboard.
    @Test func pinnedRowFarAwayKeepsTheKeyboard() async throws {
        let harness = try RichListHarness(Self.paragraphs + "\n\n" + Self.paragraphs, height: 300)
        defer { harness.close() }
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textView = try #require(harness.focusedTextView)
        for step in 1...20 {
            harness.list.view.contentOffset.y = CGFloat(step) * 300
            try await harness.settle(10)
        }
        #expect(textView.isFirstResponder)
        #expect(textView.window != nil)
        try harness.type("x")
        #expect(harness.model.row(at: 0).block.plainText?.hasPrefix("Px") == true)
    }

    /// Typing past the line end grows the row. The row keeps the keyboard.
    @Test func heightChangeKeepsTheFocus() async throws {
        let harness = try RichListHarness("a\n\nb")
        defer { harness.close() }
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textView = try #require(harness.focusedTextView)
        let before = harness.list.itemFrame(at: 0).height
        try harness.type(String(repeating: " word", count: 40))
        try await harness.settle(100)
        #expect(harness.list.itemFrame(at: 0).height > before)
        #expect(harness.focusedTextView === textView)
    }

    @Test func tapBelowTheLastRowPlacesTheCaretAtTheEnd() async throws {
        let harness = try RichListHarness("text\n\n```\ncode\n```")
        defer { harness.close() }
        harness.adapter.placeCaretAtEnd()
        try await harness.waitUntil { harness.focusedTextView != nil }
        #expect(harness.model.rowCount == 3)
        #expect(harness.model.selection == .caret(position(2, 0)))
        #expect(harness.focusedTextView?.text == "")
    }

    @Test func tabIndentsTheListItemAndKeepsTheFocus() async throws {
        let harness = try RichListHarness("- a\n- b")
        defer { harness.close() }
        harness.focus(row: 1, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textView = try #require(harness.focusedTextView)
        let tab = try #require(textView.keyCommands?.first { $0.input == "\t" && $0.modifierFlags.isEmpty })
        textView.perform(tab.action)
        // One more nesting level gives the row a new text view. It takes the keyboard after the old one leaves.
        try await harness.waitUntil { harness.focusedTextView?.text == "b" }
        #expect(harness.model.row(at: 1).block == bullet("b", indent: 1))
        #expect(harness.adapter.chrome[1].decorations.count == 2)
        #expect(harness.model.isFocused)
    }

    @Test func arrowDownLeavesTheRow() async throws {
        let harness = try RichListHarness("ab\n\ncd")
        defer { harness.close() }
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textView = try #require(harness.focusedTextView)
        let down = try #require(textView.keyCommands?.first { $0.input == UIKeyCommand.inputDownArrow && $0.modifierFlags.isEmpty })
        textView.perform(down.action)
        try await harness.waitUntil { harness.focusedTextView?.text == "cd" }
        #expect(harness.model.selection == .caret(position(1, 0)))
    }

    /// An empty text view draws its caret with its own font. The new row after Enter must use the row's font.
    @Test func caretInANewEmptyRowIsAsTallAsInARowWithText() async throws {
        let harness = try RichListHarness("- [ ] Open task\n- [x] Done task")
        defer { harness.close() }
        harness.focus(row: 0, caret: 9)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textRowCaret = try #require(caretHeight(harness))
        try harness.type("\n")
        try await harness.waitUntil { harness.focusedTextView?.text == "" }
        let emptyRowCaret = try #require(caretHeight(harness))
        #expect(abs(emptyRowCaret - textRowCaret) < 0.5, "empty row caret \(emptyRowCaret), text row caret \(textRowCaret)")
    }

    /// The same rule for every row kind: an empty row's caret is as tall as the caret in a row of that kind with text.
    @Test(arguments: [
        "# Heading\n\n#",
        "```\ncode\n```\n\n```\n```",
        "- item\n- "
    ])
    func emptyRowCaretIsAsTallAsInARowWithText(_ markdown: String) async throws {
        let harness = try RichListHarness(markdown, height: 400)
        defer { harness.close() }
        harness.focus(row: 0, caret: 0)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textRowCaret = try #require(caretRect(harness))
        harness.focus(row: 1, caret: 0)
        try await harness.waitUntil { harness.focusedTextView?.text == "" }
        let emptyRowCaret = try #require(caretRect(harness))
        #expect(abs(emptyRowCaret.height - textRowCaret.height) < 0.5, "empty \(emptyRowCaret.height), text \(textRowCaret.height)")
    }

    /// Code stays left to right in a right-to-left layout, also when the code row is empty. Other empty rows start on the right.
    @Test func emptyCodeRowCaretIsOnTheLeftInRightToLeft() async throws {
        let harness = try RichListHarness("```\ncode\n```\n\n```\n```\n\n- ", layoutDirection: .rightToLeft)
        defer { harness.close() }
        harness.focus(row: 0, caret: 0)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textRowCaret = try #require(caretRect(harness))
        harness.focus(row: 1, caret: 0)
        try await harness.waitUntil { harness.focusedTextView?.text == "" }
        let emptyRowCaret = try #require(caretRect(harness))
        #expect(abs(emptyRowCaret.minX - textRowCaret.minX) < 2, "empty \(emptyRowCaret.minX), text \(textRowCaret.minX)")
        harness.focus(row: 2, caret: 0)
        try await harness.waitUntil { harness.focusedTextView != nil && harness.focusedTextView === harness.textView(row: 2) }
        let textView = try #require(harness.focusedTextView)
        let emptyItemCaret = try #require(caretRect(harness))
        #expect(emptyItemCaret.minX > textView.bounds.width / 2, "empty list item caret \(emptyItemCaret.minX) of \(textView.bounds.width)")
    }

    private func caretHeight(_ harness: RichListHarness) -> CGFloat? {
        caretRect(harness)?.height
    }

    private func caretRect(_ harness: RichListHarness) -> CGRect? {
        guard let textView = harness.focusedTextView, let position = textView.selectedTextRange?.start else { return nil }
        return textView.caretRect(for: position)
    }
}
