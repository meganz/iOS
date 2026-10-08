import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. Atomic rows, the selection responder, the toolbar and the link dialog in a window.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichEditorControlsTests {
    /// Records what the editor forwards to the owner of selection over rows.
    private final class SelectionHandler: RichSelectionHandler {
        var extended: [(row: Int, edge: RichTextView.Edge)] = []
        var typed: [String] = []
        var backspaces = 0
        var modelChanges = 0

        func extendSelection(fromRow row: Int, through edge: RichTextView.Edge) { extended.append((row, edge)) }
        func insertText(_ text: String) -> Bool {
            typed.append(text)
            return true
        }
        func deleteBackward() -> Bool {
            backspaces += 1
            return true
        }
        func modelDidChange() { modelChanges += 1 }
        var selectAllCount = 0
        func selectAll() { selectAllCount += 1 }
    }

    @Test func selectionHandlerHearsEveryActionOnce() async throws {
        let harness = try RichListHarness("ab\n\ncd")
        defer { harness.close() }
        let handler = SelectionHandler()
        harness.adapter.selectionHandler = handler
        harness.model.select(.caret(position(1, 1)))
        harness.model.insertParagraphBreak()
        harness.model.undo()
        harness.model.selectAll()
        #expect(handler.modelChanges == 4)
    }

    @Test func responderEditActionsFollowTheSelection() async throws {
        let harness = try RichListHarness("ab\n\n---\n\ncd")
        defer { harness.close() }
        let responder = harness.adapter.responder
        let pasteboard = try #require(UIPasteboard(name: UIPasteboard.Name("RichEditorControlsTests"), create: true))
        pasteboard.items = []
        responder.pasteboard = pasteboard
        harness.model.select(.caret(position(1, 1)))
        #expect(!responder.canPerformAction(#selector(RichSelectionResponder.copy(_:)), withSender: nil))
        #expect(!responder.canPerformAction(#selector(RichSelectionResponder.delete(_:)), withSender: nil))
        #expect(responder.canPerformAction(#selector(RichSelectionResponder.selectAll(_:)), withSender: nil))
        #expect(!responder.canPerformAction(#selector(RichSelectionResponder.paste(_:)), withSender: nil))
        harness.model.select(RichSelection(start: position(0, 1), end: position(2, 1)))
        #expect(responder.canPerformAction(#selector(RichSelectionResponder.copy(_:)), withSender: nil))
        #expect(responder.canPerformAction(#selector(RichSelectionResponder.cut(_:)), withSender: nil))
        responder.copy(nil)
        // The divider copies as an empty line.
        #expect(pasteboard.string == "b\n\nc")
        #expect(responder.canPerformAction(#selector(RichSelectionResponder.paste(_:)), withSender: nil))
        responder.delete(nil)
        #expect(harness.model.rowCount == 1)
        #expect(harness.model.row(at: 0).block == paragraph("ad"))
    }

    /// With a selection owner, Select All in a row or the responder goes to it, so it can show its menu.
    @Test func selectAllGoesToTheSelectionHandler() async throws {
        let harness = try RichListHarness("ab\n\n---")
        defer { harness.close() }
        let handler = SelectionHandler()
        harness.adapter.selectionHandler = handler
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        harness.focusedTextView?.selectAll(nil)
        harness.adapter.responder.selectAll(nil)
        #expect(handler.selectAllCount == 2)
        #expect(harness.model.selection == .caret(position(0, 1)))
    }

    /// ⌘A in a text row selects the whole document. The selection responder then has the keyboard.
    @Test func selectAllInARowSelectsTheDocument() async throws {
        let harness = try RichListHarness("ab\n\ncd")
        defer { harness.close() }
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        harness.focusedTextView?.selectAll(nil)
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        #expect(harness.model.selection == RichSelection(start: position(0, 0), end: position(1, 2)))
    }

    @Test func tapOnADividerSelectsItAndTheResponderTakesTheKeyboard() async throws {
        let harness = try RichListHarness("a\n\n---\n\nb")
        defer { harness.close() }
        harness.adapter.selectAtomic(row: 1)
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        #expect(harness.model.selection == .range(0..<1, inBlock: 1))
        #expect(harness.list.pinnedItem == nil)
        #expect(harness.model.isFocused)
    }

    @Test func backspaceDeletesTheSelectedDivider() async throws {
        let harness = try RichListHarness("a\n\n---\n\nb")
        defer { harness.close() }
        harness.adapter.selectAtomic(row: 1)
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        harness.adapter.responder.deleteBackward()
        try await harness.settle()
        #expect(harness.model.rowCount == 2)
        #expect(harness.list.itemCount == 2)
    }

    /// Typing at a divider starts a paragraph next to it, and the new row takes the keyboard.
    @Test func typingAtADividerStartsAParagraph() async throws {
        let harness = try RichListHarness("a\n\n---")
        defer { harness.close() }
        harness.model.setFocused(true)
        harness.model.select(.caret(position(1, 1)))
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        harness.adapter.responder.insertText("x")
        try await harness.waitUntil { harness.focusedTextView?.text == "x" }
        #expect(harness.model.rowCount == 3)
        #expect(harness.model.row(at: 2).block == paragraph("x"))
    }

    @Test func arrowDownFromADividerGoesToTheNextRow() async throws {
        let harness = try RichListHarness("a\n\n---\n\nb")
        defer { harness.close() }
        harness.adapter.selectAtomic(row: 1)
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        let down = try #require(harness.adapter.responder.keyCommands?.first { $0.input == UIKeyCommand.inputDownArrow && $0.modifierFlags.isEmpty })
        harness.adapter.responder.perform(down.action)
        try await harness.waitUntil { harness.focusedTextView?.text == "b" }
        #expect(harness.model.selection == .caret(position(2, 0)))
    }

    /// A selection over rows has no text view. Its keys go to the selection owner.
    @Test func keysOverRowsGoToTheSelectionHandler() async throws {
        let harness = try RichListHarness("ab\n\ncd")
        defer { harness.close() }
        let handler = SelectionHandler()
        harness.adapter.selectionHandler = handler
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: position(0, 1), end: position(1, 1)))
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        harness.adapter.responder.insertText("x")
        harness.adapter.responder.deleteBackward()
        #expect(handler.typed == ["x"])
        #expect(handler.backspaces == 1)
        #expect(harness.model.rowCount == 2)
    }

    @Test func shiftArrowAtTheRowEdgeGoesToTheSelectionHandler() async throws {
        let harness = try RichListHarness("ab\n\ncd")
        defer { harness.close() }
        let handler = SelectionHandler()
        harness.adapter.selectionHandler = handler
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textView = try #require(harness.focusedTextView)
        let shiftDown = try #require(textView.keyCommands?.first { $0.input == UIKeyCommand.inputDownArrow && $0.modifierFlags == .shift })
        textView.perform(shiftDown.action)
        #expect(handler.extended.map(\.row) == [0])
        #expect(handler.extended.map(\.edge) == [.down])
    }

    @Test func boldButtonStylesTheNextKey() async throws {
        let harness = try RichListHarness("ab")
        defer { harness.close() }
        harness.focus(row: 0, caret: 2)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let bold = try #require(RichFormattingToolbar.buttons(model: harness.model, strings: .english).first { $0.id == "bold" })
        #expect(bold.isEnabled)
        bold.action()
        #expect(harness.model.toolbar.activeStyles == [.bold])
        try harness.type("c")
        #expect(harness.model.row(at: 0).block == paragraph("abc", (2..<3, .bold)))
        let textView = try #require(harness.focusedTextView)
        let font = try #require(textView.attributedText.attribute(.font, at: 2, effectiveRange: nil) as? UIFont)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    /// A heading gets other views around its text, so SwiftUI makes a new text view. It gets the keyboard back.
    @Test func headingPickKeepsTheKeyboard() async throws {
        let harness = try RichListHarness("Title\n\nbody")
        defer { harness.close() }
        harness.focus(row: 0, caret: 2)
        try await harness.waitUntil { harness.focusedTextView != nil }
        harness.model.apply(.setHeading(1))
        try await harness.waitUntil { harness.focusedTextView?.text == "Title" && harness.model.toolbar.headingLevel == 1 }
        #expect(harness.model.isFocused)
        #expect(harness.focusedTextView?.selectedRange == NSRange(location: 2, length: 0))
    }

    /// Counts text view focus changes while a row gets a new text view (a new nesting level or a heading).
    /// Each replaced view ends editing once and its successor begins once, so the keyboard can flicker.
    private func focusChanges(_ harness: RichListHarness, during action: () -> Void) async throws -> (ends: Int, begins: Int) {
        let before = harness.focusedTextView
        var ends = 0
        var begins = 0
        let center = NotificationCenter.default
        let endObserver = center.addObserver(forName: UITextView.textDidEndEditingNotification, object: nil, queue: nil) { _ in
            MainActor.assumeIsolated { ends += 1 }
        }
        let beginObserver = center.addObserver(forName: UITextView.textDidBeginEditingNotification, object: nil, queue: nil) { _ in
            MainActor.assumeIsolated { begins += 1 }
        }
        defer {
            center.removeObserver(endObserver)
            center.removeObserver(beginObserver)
        }
        action()
        try await harness.waitUntil { harness.focusedTextView != nil && harness.focusedTextView !== before }
        try await harness.settle(100)
        return (ends, begins)
    }

    @Test func tabCountsOneFocusHandOver() async throws {
        let harness = try RichListHarness("- a\n- b")
        defer { harness.close() }
        harness.focus(row: 1, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let changes = try await focusChanges(harness) { harness.model.apply(.indent) }
        #expect(harness.focusedTextView?.text == "b")
        #expect(changes.ends == 1, "ends \(changes.ends), begins \(changes.begins)")
        #expect(changes.begins == 1, "ends \(changes.ends), begins \(changes.begins)")
    }

    @Test func headingPickCountsOneFocusHandOver() async throws {
        let harness = try RichListHarness("Title")
        defer { harness.close() }
        harness.focus(row: 0, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let changes = try await focusChanges(harness) { harness.model.apply(.setHeading(1)) }
        #expect(harness.focusedTextView?.text == "Title")
        #expect(changes.ends == 1, "ends \(changes.ends), begins \(changes.begins)")
        #expect(changes.begins == 1, "ends \(changes.ends), begins \(changes.begins)")
    }

    @Test func linkButtonOpensTheDialog() async throws {
        let harness = try RichListHarness("go here")
        defer { harness.close() }
        harness.model.setFocused(true)
        harness.model.select(.range(3..<7, inBlock: 0))
        try await harness.waitUntil { harness.focusedTextView != nil }
        let link = try #require(RichFormattingToolbar.buttons(model: harness.model, strings: .english).first { $0.id == "link" })
        link.action()
        #expect(harness.model.linkDialog?.draft.text == "here")
        #expect(harness.model.saveLink(urlText: "https://mega.nz", label: "here"))
        #expect(harness.model.linkDialog == nil)
    }

    @Test func checkboxToggleFromTheRowReachesTheModel() async throws {
        let harness = try RichListHarness("- [ ] task\n- [x] done")
        defer { harness.close() }
        harness.model.toggleCheckbox(inRow: 1)
        try await harness.settle()
        #expect(harness.model.row(at: 1).block == task("done", checked: false))
        #expect(harness.list.itemCount == 2)
    }
}
