import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. Rich mode in a window: typing, Enter, Backspace and undo move the focus between rows.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichRowAdapterTests {
    private static let paragraphs = (0..<80).map { "Paragraph \($0) with some words." }.joined(separator: "\n\n")

    @Test func showsEveryRowKind() async throws {
        let table = "| a |\n|---|\n" + (0..<120).map { "| \($0) |" }.joined(separator: "\n")
        let harness = try RichListHarness("# Title\n\nText\n\n- item\n\n> quote\n\n```\ncode\n```\n\n---\n\n" + table)
        defer { harness.close() }
        try await harness.settle()
        // 6 rows of one item, and a raw table of 3 pages.
        #expect(harness.model.rowCount == 7)
        #expect(harness.list.itemCount == 9)
        #expect(harness.textView(row: 0)?.text == "Title")
        #expect(harness.textView(row: 4)?.text == "code")
        #expect(harness.textView(row: 5) == nil)
    }

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

    /// A cell that scrolls away is reused for another row. Its text view must show the new row's text.
    @Test func scrollingShowsEachRowItsOwnText() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 400)
        defer { harness.close() }
        try await scrollDownAndCheckText(harness)
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

    /// A paste that adds rows changes the model before the list update. Cells that UIKit makes in that gap,
    /// for example prefetched cells below the screen, must still show their own row at their own height.
    @Test func scrollingAfterAPasteThatAddsRowsShowsEachRowItsOwnTextAndHeight() async throws {
        let markdown = """
        # A long title that wraps over two lines on a phone

        > **A quote** with a list:
        >
        > 1. The first step of the quote, long enough to wrap over two lines.
        > 2. The second step of the quote, long enough to wrap over two lines.

        ## A heading

        A paragraph before the list.

        - Bullet one
        - Bullet two
          - Nested bullet

        1. Ordered one
        2. Ordered two

        - [ ] Open task
        - [x] Done task

        > A quote with *emphasis*.

        ---

        ### Another heading

        A paragraph after the divider.
        """
        let harness = try RichListHarness(markdown)
        defer { harness.close() }
        try await harness.settle(200)
        let row = try #require((0..<harness.model.rowCount).first { harness.model.row(at: $0).block.plainText == "A paragraph before the list." })
        harness.focus(row: row, caret: 2)
        try await harness.settle(100)
        harness.model.paste(RichPasteContent(markdown: "- [ ] Pasted A\n- [x] Pasted B\n- Bullet C\n"))
        try await harness.settle(300)

        let view = harness.list.view
        var wrong: [String] = []
        for step in 0..<8 {
            view.contentOffset.y = CGFloat(step) * 120 - view.adjustedContentInset.top
            try await harness.settle(60)
            for item in view.indexPathsForVisibleItems.map(\.item) {
                let row = harness.adapter.row(forItem: item).row
                guard let text = harness.model.row(at: row).block.plainText,
                      let cell = harness.list.cell(forItem: item) else { continue }
                let shown = harness.adapter.textView(forItem: item)?.text
                let fitted = ceil(cell.contentView.systemLayoutSizeFitting(
                    CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                ).height)
                let height = harness.list.itemFrame(at: item).height
                if shown != text || abs(fitted - height) > 0.5 {
                    wrong.append("item \(item) '\(text)': shows '\(shown ?? "nil")', height \(height), content \(fitted)")
                }
            }
        }
        #expect(wrong.isEmpty, "\(wrong)")
    }

    /// Every row has the same model version. A reused cell must take its new row's text before it measures itself.
    /// Else a long row keeps the height of the short row the cell showed before.
    @Test func fastScrollToTheEndGivesReusedCellsTheHeightOfTheirOwnText() async throws {
        let long = "A long task item that wraps over several lines on a phone screen, so its row is much taller than one line."
        let short = (0..<30).map { "Paragraph \($0)\n\n- Bullet \($0)\n- [ ] Task \($0)" }.joined(separator: "\n\n")
        let markdown = short + "\n\n" + (0..<4).map { "- [x] \($0) \(long)" }.joined(separator: "\n")
        let harness = try RichListHarness(markdown)
        defer { harness.close() }
        try await harness.settle(200)

        let view = harness.list.view
        let maxOffset = { view.contentSize.height + view.adjustedContentInset.bottom - view.bounds.height }
        while view.contentOffset.y < maxOffset() - 0.5 {
            view.contentOffset.y = min(view.contentOffset.y + 900, maxOffset())
            view.layoutIfNeeded()
        }
        try await harness.settle(300)

        var wrong: [String] = []
        for item in view.indexPathsForVisibleItems.map(\.item) {
            guard let cell = harness.list.cell(forItem: item) else { continue }
            let fitted = ceil(cell.contentView.systemLayoutSizeFitting(
                CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height)
            let height = harness.list.itemFrame(at: item).height
            if abs(fitted - height) > 0.5 {
                wrong.append("item \(item): height \(height), content \(fitted)")
            }
        }
        #expect(wrong.isEmpty, "\(wrong)")
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

    @Test func checkboxTapTogglesTheTask() async throws {
        let harness = try RichListHarness("- [ ] task")
        defer { harness.close() }
        harness.model.toggleCheckbox(inRow: 0)
        try await harness.settle()
        #expect(harness.model.row(at: 0).block == task("task", checked: true))
        guard case .listItem(.checkbox(isChecked: true), _)? = harness.adapter.chrome[0].decorations.first else {
            Issue.record("the chrome did not follow: \(harness.adapter.chrome[0])")
            return
        }
    }
}
