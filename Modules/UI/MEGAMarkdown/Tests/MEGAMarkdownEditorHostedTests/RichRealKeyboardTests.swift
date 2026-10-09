import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator with the software keyboard on (I/O > Keyboard > Connect Hardware Keyboard off).
// The window is key, so the real keyboard shows. Each test waits until the keyboard and the list are still.
// The window starts at the screen origin, so screen and window coordinates are the same.
@MainActor
@Suite(.serialized, .hostedUI, .realKeyboard, .timeLimit(.minutes(1)))
struct RichRealKeyboardTests {
    private static let paragraphs = (0..<80).map { "Paragraph \($0) with some words." }.joined(separator: "\n\n")
    private static let shortParagraphs = (0..<100).map { "Paragraph \($0)." }.joined(separator: "\n\n")

    /// A rotation changes the width, so every row wraps again. The caret must stay above the keyboard.
    @Test func widthChangeKeepsTheCaretRowOnScreen() async throws {
        let keyboard = try await KeyboardWatcher.startHidden()
        let harness = try RichListHarness(Self.paragraphs, width: 390, height: 700, isKey: true)
        defer { harness.close() }
        harness.focus(row: 70, caret: 1)
        let keyboardTop = try await waitForKeyboard(keyboard, in: harness)
        try expectCaretVisible(in: harness, above: keyboardTop)
        harness.resize(width: 844, height: 390)
        try await waitForStillList(harness)
        try expectCaretVisible(in: harness, above: keyboardTop)
        harness.resize(width: 390, height: 700)
        try await waitForStillList(harness)
        try expectCaretVisible(in: harness, above: keyboardTop)
        #expect(harness.model.selection == .caret(position(70, 1)))
    }

    /// ⇧↑ grows the selection up past the top of the screen. The head row must show above the keyboard.
    @Test func shiftUpPastTheScreenShowsTheHead() async throws {
        let keyboard = try await KeyboardWatcher.startHidden()
        let harness = try RichListHarness(Self.shortParagraphs, height: 700, isKey: true)
        defer { harness.close() }
        let controller = try #require(harness.selectionController)
        harness.focus(row: 50, caret: 0)
        let keyboardTop = try await waitForKeyboard(keyboard, in: harness)
        try #require(harness.focusedTextView === harness.textView(row: 50))

        for _ in 0..<15 {
            controller.extendSelection(fromRow: controller.selection?.head.blockIndex ?? 50, through: .up)
            try await harness.settle(30)
        }
        try await waitForStillList(harness)

        #expect(controller.selection?.head == position(35, 0))
        let head = harness.list.view.convert(harness.list.itemFrame(at: harness.adapter.items(forRow: 35).lowerBound), to: nil)
        let visible = try visibleArea(in: harness, above: keyboardTop)
        #expect(visible.intersects(head), "head row \(head) is outside \(visible)")
    }

    // MARK: - Helpers

    /// Waits for keyboardDidShow and a still list. Returns the keyboard top in window coordinates.
    private func waitForKeyboard(_ keyboard: KeyboardWatcher, in harness: RichListHarness) async throws -> CGFloat {
        let frame = try await waitForValue("keyboardDidShow") { keyboard.frame }
        try await waitForStillList(harness)
        let keyboardTop = harness.window.convert(frame, from: harness.window.screen.coordinateSpace).minY
        // A keyboard below the window would make every check pass.
        try #require(keyboardTop < harness.window.bounds.height, "keyboard top \(keyboardTop) is below the window")
        return keyboardTop
    }

    /// Waits until the list size and scroll offset stay the same for about 300 ms.
    private func waitForStillList(_ harness: RichListHarness) async throws {
        var last = CGRect.null
        var stillPolls = 0
        try await harness.waitUntil("a still list") {
            let bounds = harness.list.view.bounds
            stillPolls = bounds == last ? stillPolls + 1 : 0
            last = bounds
            return stillPolls >= 30
        }
    }

    /// The part of the list on screen, above `bottom`, in window coordinates.
    private func visibleArea(in harness: RichListHarness, above bottom: CGFloat) throws -> CGRect {
        let view = harness.list.view
        // A row in the top content inset does not count as visible, like in the hosted tests.
        let list = view.convert(view.bounds.inset(by: UIEdgeInsets(top: view.adjustedContentInset.top, left: 0, bottom: 0, right: 0)), to: nil)
        let maxY = min(list.maxY, bottom)
        try #require(maxY > list.minY, "nothing of the list is above \(bottom)")
        return CGRect(x: list.minX, y: list.minY, width: list.width, height: maxY - list.minY)
    }

    /// The caret is inside the list and above `bottom`, in window coordinates.
    private func expectCaretVisible(in harness: RichListHarness, above bottom: CGFloat) throws {
        let textView = try #require(harness.focusedTextView)
        let position = try #require(textView.selectedTextRange?.end)
        let caret = textView.convert(textView.caretRect(for: position), to: nil)
        let visible = try visibleArea(in: harness, above: bottom)
        #expect(caret.minY >= visible.minY && caret.maxY <= visible.maxY, "caret \(caret) is outside \(visible.minY)...\(visible.maxY)")
    }
}

/// Follows keyboardDidShow and keyboardDidHide. One shared instance sees the notes of every test.
@MainActor
private final class KeyboardWatcher {
    private static let shared = KeyboardWatcher()
    /// The keyboard frame after keyboardDidShow, in screen coordinates. nil after keyboardDidHide.
    private var shownFrame: CGRect?
    private var showCount = 0
    private var startCount = 0
    private var observers: [any NSObjectProtocol] = []

    /// The frame of the first keyboard shown after `startHidden()`. nil until then.
    var frame: CGRect? { showCount > startCount ? shownFrame : nil }

    /// Starts each test without a keyboard, also after a failed test.
    /// The test host has no window scene. Closing a window there leaves the keyboard up, and no note arrives.
    /// A resign in a window that stays on screen hides it and posts keyboardDidHide.
    static func startHidden() async throws -> KeyboardWatcher {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 100))
        let controller = UIViewController()
        let field = UITextField(frame: controller.view.bounds)
        controller.view.addSubview(field)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let shows = shared.showCount
        field.becomeFirstResponder()
        try await waitUntil("the keyboard to show for the reset") { shared.showCount > shows }
        field.resignFirstResponder()
        try await waitUntil("the keyboard to hide for the reset") { shared.shownFrame == nil }
        shared.startCount = shared.showCount
        return shared
    }

    private init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { [weak self] note in
            let frame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            MainActor.assumeIsolated {
                self?.shownFrame = frame
                self?.showCount += 1
            }
        })
        observers.append(center.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.shownFrame = nil }
        })
    }
}
