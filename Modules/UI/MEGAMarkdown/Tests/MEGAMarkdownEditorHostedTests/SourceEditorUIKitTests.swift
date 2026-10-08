import Foundation
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. Hosts the real MarkdownEditor and types into its source text view.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct SourceEditorUIKitTests {
    private func makeHost(_ text: String, mode: MarkdownEditorMode = .source) async throws -> EditorWindow {
        let host = EditorWindow(text, mode: mode)
        _ = try await host.waitForSourceTextView()
        return host
    }

    /// Types like a programmatic insert at the end.
    private func type(_ text: String, into textView: UITextView) {
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: (textView.text as NSString).length, length: 0)
        textView.insertText(text)
    }

    /// Text with accents, CJK and emoji, 10 MB by default. Non-ASCII makes bridged string compares slow.
    private func largeNonASCIIText(bytes: Int = 10_000_000) -> String {
        let line = "Café naïve 日本語 😀 word **bold** [link](https://mega.io) end\n"
        return String(repeating: line, count: bytes / line.utf8.count)
    }

    // MARK: - Text view

    @Test func staysOnTextKit1() async throws {
        let host = try await makeHost("abc")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        type("x", into: textView)
        #expect(textView.textLayoutManager == nil)
        #expect(textView.layoutManager.allowsNonContiguousLayout)
        #expect(textView.isFindInteractionEnabled)
        #expect(textView.smartQuotesType == .no)
        #expect(textView.spellCheckingType == .no)
    }

    /// A jump to the end of a long text (Find, ⌘↓) lands within two frames. An animated scroll would still be far away.
    @Test func farCaretJumpDoesNotAnimate() async throws {
        let text = String(repeating: "A line of source text.\n", count: 20_000)
        let host = try await makeHost(text)
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: 0, length: 0)
        try await EditorWindow.settle()
        let end = NSRange(location: (textView.text as NSString).length, length: 0)
        textView.selectedRange = end
        textView.scrollRangeToVisible(end)
        try await waitUntil("the jump to the end") { textView.contentOffset.y > textView.bounds.height * 10 }
        // Non-contiguous layout corrects the content height while it scrolls, so read it after.
        let bottom = textView.contentSize.height - textView.bounds.height
        #expect(bottom > textView.bounds.height * 10)
        #expect(textView.contentOffset.y > bottom - textView.bounds.height, "offset \(textView.contentOffset.y), bottom \(bottom)")
    }

    // MARK: - Writes to the binding

    @Test func typingDoesNotWriteTheBinding() async throws {
        let host = try await makeHost("abc")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        type("x", into: textView)
        try await EditorWindow.settle()
        #expect(host.model.writes.isEmpty)
        #expect(textView.text == "abcx")
    }

    @Test func idleWritesTheExactText() async throws {
        let host = try await makeHost("a\r\nb")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        type("x", into: textView)
        try await waitUntil("the idle write", timeout: .seconds(5)) { !host.model.writes.isEmpty }
        #expect(host.model.writes == ["a\r\nbx"])
    }

    /// CRLF line ends and a raw HTML block go to rich mode and back with no edit. Nothing is written.
    @Test func untouchedTextIsNeverWritten() async throws {
        let text = "a\r\n\r\n<div>x</div>\r\n"
        let host = try await makeHost(text)
        defer { host.close() }
        host.model.mode = .rich
        _ = try await host.waitForRichRow("a")
        host.model.mode = .source
        let textView = try await host.waitForSourceTextView()
        // Negative wait: nothing may be written after the switch.
        try await EditorWindow.settle(300)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        #expect(textView.text.hasSameBytes(as: text))
        host.model.isShown = false
        try await EditorWindow.settle()
        #expect(host.model.writes.isEmpty)
    }

    @Test func modeSwitchWritesTheLastKey() async throws {
        let host = try await makeHost("# Title\n")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        type("x", into: textView)
        host.model.mode = .rich
        try await EditorWindow.settle()
        #expect(host.model.writes == ["# Title\nx"])
    }

    @Test func disappearKeepsTheLastKey() async throws {
        let host = try await makeHost("abc")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        type("x", into: textView)
        host.model.isShown = false
        try await EditorWindow.settle()
        #expect(host.model.writes == ["abcx"])
    }

    // On iOS 26 SwiftUI removes the view before `onDisappear`, and the weak text view is gone by then.
    @Test func flushUsesTheTextOfARemovedView() {
        let sync = SourceTextSync()
        var written: [String] = []
        sync.onFlush = { written.append($0) }
        var textView: UITextView? = UITextView(usingTextLayoutManager: false)
        textView?.text = sync.startText(for: "abc")
        sync.textView = textView
        textView?.text = "abcx"
        sync.didEdit()
        let coordinator = SourceTextView(markdown: "abc", sync: sync).makeCoordinator()
        if let textView { SourceTextView.dismantleUIView(textView, coordinator: coordinator) }
        textView = nil
        // UIKit may keep the view alive a little longer. Drop the weak reference like a freed view.
        sync.textView = nil
        #expect(sync.flush())
        #expect(written == ["abcx"])
        #expect(!sync.flush())
    }

    @Test func backgroundKeepsTheLastKey() async throws {
        let host = try await makeHost("abc")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        type("x", into: textView)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        #expect(host.model.writes == ["abcx"])
    }

    @Test func outsideChangeWinsAndClearsUndo() async throws {
        let host = try await makeHost("abc")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        type("x", into: textView)
        #expect(textView.undoManager?.canUndo == true)
        host.model.text = "new text"
        let newView = try await waitForValue("the new source text view") {
            host.sourceTextView.flatMap { $0.text == "new text" ? $0 : nil }
        }
        // A nil undo manager would pass the check below with no undo history to look at.
        let undoManager = try #require(newView.undoManager)
        #expect(!undoManager.canUndo)
        // Negative wait: longer than the 1 s idle delay of the source text view.
        try await EditorWindow.settle(1_300)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        #expect(host.model.writes.isEmpty)
    }

    // MARK: - Large text

    /// A published binding, non-ASCII 10 MB, a key near the end, then the idle flush.
    /// A bridged NSString in the binding froze main for seconds. The timing is in the benchmarks.
    @Test func idleFlushOfLargeTextWritesTheText() async throws {
        let host = try await makeHost(largeNonASCIIText())
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        try await EditorWindow.settle(500)
        textView.becomeFirstResponder()
        let length = (textView.text as NSString).length
        textView.selectedRange = NSRange(location: length * 95 / 100, length: 0)
        textView.insertText("abc")
        try await waitUntil("the idle flush", timeout: .seconds(20)) { !host.model.writes.isEmpty }
        #expect(host.model.writes.count == 1)
        #expect(host.model.text.utf16.count == length + 3)
    }

    /// A key in the middle of 2 MB edits in place, and the background flush writes the text once.
    /// Two arguments at 10 MB would come near the 50 s cap of a hosted test. The 10 MB case is above.
    @Test(arguments: [false, true])
    func insertInLargeTextWritesOnceOnBackground(isNonASCII: Bool) async throws {
        let line = String(repeating: "word ", count: 19) + "end\n"
        let text = isNonASCII ? largeNonASCIIText(bytes: 2_000_000) : String(repeating: line, count: 2_000_000 / line.utf8.count)
        let host = try await makeHost(text)
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        textView.becomeFirstResponder()
        let middle = (textView.text as NSString).length / 2
        for index in 0..<20 {
            textView.selectedRange = NSRange(location: middle + index, length: 0)
            textView.insertText("x")
        }
        #expect(host.model.writes.isEmpty)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        try await waitUntil("the background flush", timeout: .seconds(20)) { !host.model.writes.isEmpty }
        #expect(host.model.writes.count == 1)
    }
}
