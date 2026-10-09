@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. The window starts at the screen origin, so window and screen coordinates are the same.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct KeyboardOverlapTests {
    private func makeView() -> (window: UIWindow, view: UIView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        window.isHidden = false
        return (window, view)
    }

    private func show(_ frame: CGRect, in keyboard: KeyboardOverlap) async throws {
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame)]
        )
        try await waitUntil("the keyboard frame \(frame)") { keyboard.frame == frame }
    }

    @Test func hiddenKeyboardOverlapsNothing() {
        let (window, view) = makeView()
        defer { window.isHidden = true }
        #expect(KeyboardOverlap().overlap(with: view) == 0)
    }

    @Test func dockedKeyboardOverlapsTheBottomPart() async throws {
        let (window, view) = makeView()
        defer { window.isHidden = true }
        let keyboard = KeyboardOverlap()
        try await show(CGRect(x: 0, y: 400, width: 390, height: 300), in: keyboard)
        #expect(keyboard.overlap(with: view) == 300)
    }

    @Test func keyboardBelowTheViewOverlapsNothing() async throws {
        let (window, view) = makeView()
        defer { window.isHidden = true }
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 400)
        let keyboard = KeyboardOverlap()
        // The keyboard starts exactly where the view ends, then further down.
        try await show(CGRect(x: 0, y: 400, width: 390, height: 300), in: keyboard)
        #expect(keyboard.overlap(with: view) == 0)
        try await show(CGRect(x: 0, y: 500, width: 390, height: 200), in: keyboard)
        #expect(keyboard.overlap(with: view) == 0)
    }

    @Test func hideNotificationClearsTheOverlap() async throws {
        let (window, view) = makeView()
        defer { window.isHidden = true }
        let keyboard = KeyboardOverlap()
        try await show(CGRect(x: 0, y: 400, width: 390, height: 300), in: keyboard)
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil)
        try await waitUntil("the hidden keyboard") { keyboard.frame == nil }
        #expect(keyboard.overlap(with: view) == 0)
    }

    /// A floating keyboard on an iPad sits above the bottom edge. It does not cover the last rows.
    @Test func floatingKeyboardAboveTheBottomEdgeIsAKnownDefect() async throws {
        let (window, view) = makeView()
        defer { window.isHidden = true }
        let keyboard = KeyboardOverlap()
        try await show(CGRect(x: 40, y: 200, width: 300, height: 260), in: keyboard)
        // Known problem: the overlap is the distance from the keyboard top to the view bottom, so a floating
        // keyboard adds a blank inset (500 here).
        withKnownIssue {
            #expect(keyboard.overlap(with: view) == 0)
        }
    }
}
