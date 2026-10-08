import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. The keyboard covers the bottom of the editor. The window starts at the screen origin,
// so window and screen coordinates are the same.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichKeyboardTests {
    private static let paragraphs = (0..<80).map { "Paragraph \($0) with some words." }.joined(separator: "\n\n")
    private static let keyboardTop: CGFloat = 400

    private func showKeyboard(width: CGFloat = 390, height: CGFloat = 700) {
        let frame = CGRect(x: 0, y: Self.keyboardTop, width: width, height: height - Self.keyboardTop)
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame)]
        )
    }

    private func hideKeyboard() {
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @Test func lastRowScrollsAboveTheKeyboard() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 700)
        defer {
            hideKeyboard()
            harness.close()
        }
        showKeyboard()
        try await harness.settle()
        let view = harness.list.view
        let last = harness.list.itemCount - 1
        // Rows near the end size themselves while the list scrolls there, so scroll to the end a few times.
        for _ in 0..<5 {
            view.contentOffset.y = max(-view.adjustedContentInset.top, view.contentSize.height + view.adjustedContentInset.bottom - view.bounds.height)
            try await harness.settle(20)
        }
        let lastFrame = view.convert(harness.list.itemFrame(at: last), to: nil)
        #expect(lastFrame.maxY <= Self.keyboardTop + 1, "last row ends at \(lastFrame.maxY)")
        hideKeyboard()
        try await harness.settle()
        #expect(view.contentInset.bottom == RichRowAdapter.bottomInset)
    }

    /// The scroll indicator stops above the keyboard, and the inset goes back when the keyboard hides.
    @Test func keyboardMovesTheScrollIndicatorInsetAndResetsIt() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 700)
        defer {
            hideKeyboard()
            harness.close()
        }
        let view = harness.list.view
        showKeyboard()
        try await harness.settle()
        // The list ends a little above the window bottom, so the keyboard covers less than 300 points of it.
        let covered = view.convert(view.bounds, to: nil).maxY - Self.keyboardTop
        #expect(covered > 0 && covered < 300)
        #expect(view.contentInset.bottom == RichRowAdapter.bottomInset + covered)
        #expect(view.verticalScrollIndicatorInsets.bottom == covered)
        hideKeyboard()
        try await harness.settle()
        #expect(view.contentInset.bottom == RichRowAdapter.bottomInset)
        #expect(view.verticalScrollIndicatorInsets.bottom == 0)
    }

    /// Select All keeps the place, like a system text view.
    @Test func selectAllDoesNotScroll() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 500)
        defer { harness.close() }
        // Start from a scrolled middle row, so a jump to the top would show.
        harness.focus(row: 40, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let offset = harness.list.view.contentOffset.y
        #expect(offset > 0)
        harness.model.selectAll()
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        #expect(harness.list.view.contentOffset.y == offset)
    }

    /// A range over rows that ends off screen still shows its end.
    @Test func selectionOverRowsShowsItsEnd() async throws {
        let harness = try RichListHarness(Self.paragraphs, height: 500)
        defer { harness.close() }
        harness.model.setFocused(true)
        harness.model.select(RichSelection(start: position(0, 1), end: position(70, 3)))
        try await harness.waitUntil { harness.adapter.responder.isFirstResponder }
        let item = harness.adapter.items(forRow: 70).lowerBound
        #expect(harness.list.view.bounds.contains(harness.list.itemFrame(at: item)))
    }

    @Test func sourceModeLastLineScrollsAboveTheKeyboard() async throws {
        let host = EditorWindow((0..<200).map { "Line \($0)" }.joined(separator: "\n"))
        defer {
            hideKeyboard()
            host.close()
        }
        let textView = try await host.waitForSourceTextView()
        showKeyboard()
        try await EditorWindow.settle()
        textView.layoutIfNeeded()
        // The window is 700 high, so the keyboard covers 300 points of the view.
        #expect(textView.convert(textView.bounds, to: nil).maxY == 700)
        #expect(textView.contentInset.bottom == 300)
        textView.contentOffset.y = textView.contentSize.height + textView.adjustedContentInset.bottom - textView.bounds.height
        let lastLine = textView.convert(textView.caretRect(for: textView.endOfDocument), to: nil)
        #expect(lastLine.maxY <= Self.keyboardTop + 1, "last line ends at \(lastLine.maxY)")
    }
}
