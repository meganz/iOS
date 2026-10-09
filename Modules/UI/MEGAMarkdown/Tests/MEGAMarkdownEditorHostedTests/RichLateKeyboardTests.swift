import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. The software keyboard comes up at a different time in each run.
// The caret must stay on screen whenever it arrives. The window starts at the screen origin.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichLateKeyboardTests {
    /// When the keyboard arrives. All moments come after the focus scroll.
    /// The focus scroll already handles a keyboard that came earlier.
    enum Moment: String, CaseIterable, CustomTestStringConvertible {
        case afterTheFocusScroll
        case afterEnterAtTheBottomEdge

        var testDescription: String { rawValue }
    }

    private static let paragraphs = (0..<80).map { "Paragraph \($0) with some words." }.joined(separator: "\n\n")
    private static let height: CGFloat = 700
    private static let keyboardHeight: CGFloat = 300

    /// A window that gets shorter: the list height changes, like a keyboard in a sheet or a split view.
    @Test(arguments: Moment.allCases)
    func shorterListKeepsTheCaretOnScreen(_ moment: Moment) async throws {
        let harness = try RichListHarness(Self.paragraphs, height: Self.height)
        defer { harness.close() }
        try await run(moment, in: harness) {
            harness.resize(width: 390, height: Self.height - Self.keyboardHeight)
        }
        try await harness.settle(100)
        try expectCaretVisible(in: harness, above: Self.height - Self.keyboardHeight)
    }

    /// A keyboard over the list: the list keeps its height and gets a bottom inset.
    @Test(arguments: Moment.allCases)
    func keyboardOverTheListKeepsTheCaretAboveIt(_ moment: Moment) async throws {
        let harness = try RichListHarness(Self.paragraphs, height: Self.height)
        defer {
            NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil)
            harness.close()
        }
        let keyboardTop = Self.height - Self.keyboardHeight
        let frame = CGRect(x: 0, y: keyboardTop, width: 390, height: Self.keyboardHeight)
        try await run(moment, in: harness) {
            NotificationCenter.default.post(
                name: UIResponder.keyboardWillChangeFrameNotification,
                object: nil,
                userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame)]
            )
        }
        try await harness.settle(100)
        // The list ends above the window bottom, so the keyboard covers less than its height.
        let listBottom = harness.list.view.convert(harness.list.view.bounds, to: nil).maxY
        #expect(harness.list.view.contentInset.bottom == RichRowAdapter.bottomInset + listBottom - keyboardTop)
        try expectCaretVisible(in: harness, above: keyboardTop)
    }

    /// Focuses a row near the bottom of the screen and calls `keyboard` at `moment`.
    private func run(_ moment: Moment, in harness: RichListHarness, keyboard: () -> Void) async throws {
        switch moment {
        case .afterTheFocusScroll:
            harness.focus(row: 70, caret: 1)
            try await harness.waitUntil { harness.focusedTextView != nil }
            try await harness.settle(100)
            keyboard()
        case .afterEnterAtTheBottomEdge:
            let lastVisible = try #require(harness.list.view.indexPathsForVisibleItems.map(\.item).max())
            harness.focus(row: lastVisible, caret: harness.model.row(at: lastVisible).block.length)
            try await harness.waitUntil { harness.focusedTextView != nil }
            try harness.type("\n")
            try await harness.waitUntil { harness.focusedTextView?.text == "" }
            try await harness.settle(100)
            keyboard()
        }
    }

    /// The caret is inside the list and above `bottom`, in window coordinates.
    private func expectCaretVisible(in harness: RichListHarness, above bottom: CGFloat) throws {
        let textView = try #require(harness.focusedTextView)
        let position = try #require(textView.selectedTextRange?.end)
        let caret = textView.convert(textView.caretRect(for: position), to: nil)
        let list = harness.list.view.convert(harness.list.view.bounds, to: nil)
        #expect(caret.minY >= list.minY && caret.maxY <= min(list.maxY, bottom), "caret \(caret) is outside \(list.minY)...\(bottom)")
    }
}
