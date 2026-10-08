import Foundation
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. The whole editor: mode switches, and when edits reach the binding.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct MarkdownEditorSaveTests {
    /// The writes without the last line end, which an edited file may gain.
    private func lines(_ host: EditorWindow) -> [String] {
        host.model.writes.map { $0.trimmingCharacters(in: .newlines) }
    }

    @Test func sourceToRichShowsTheLastKey() async throws {
        let host = EditorWindow("# Title\n")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: (textView.text as NSString).length, length: 0)
        textView.insertText("x")
        host.model.mode = .rich
        // The last key must show in rich mode, not only reach the binding.
        _ = try await host.waitForRichRow("x")
        #expect(host.model.writes == ["# Title\nx"])
    }

    @Test func richEditShowsAsSyntaxInSource() async throws {
        let host = EditorWindow("# Title", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("Title")
        host.typeAtEnd("x", into: row)
        host.model.mode = .source
        let textView = try await host.waitForSourceTextView()
        #expect(["# Titlex", "# Titlex\n"].contains(textView.text), "source: \(textView.text ?? "")")
        #expect(host.model.writes == [textView.text])
    }

    @Test func sourceSyntaxShowsFormattedInRich() async throws {
        let host = EditorWindow("")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        textView.becomeFirstResponder()
        textView.insertText("**bold** text")
        host.model.mode = .rich
        let row = try await host.waitForRichRow("bold text")
        let bold = try #require(row.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        #expect(bold.fontDescriptor.symbolicTraits.contains(.traitBold))
        let plain = try #require(row.attributedText.attribute(.font, at: 5, effectiveRange: nil) as? UIFont)
        #expect(!plain.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    /// The idle save writes once. Its own write coming back through the binding does not reload rich mode.
    @Test func richIdleWritesOnceAndKeepsTheRow() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("abc")
        host.typeAtEnd("x", into: row)
        try await waitUntil("the idle save") { !host.model.writes.isEmpty }
        #expect(lines(host) == ["abcx"])
        // A second save would come one delay later. Wait three delays.
        try await Task.sleep(for: EditorWindow.idleDelay * 3)
        #expect(host.model.writes.count == 1)
        #expect(host.richTextViews.first === row)
        #expect(row.isFirstResponder)
    }

    @Test func richBackgroundWritesAtOnceAndIdleDoesNotRepeat() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("abc")
        host.typeAtEnd("x", into: row)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        #expect(lines(host) == ["abcx"])
        // The idle save would write a second time one delay later. Wait three delays.
        try await Task.sleep(for: EditorWindow.idleDelay * 3)
        #expect(host.model.writes.count == 1)
    }

    @Test func richDisappearKeepsTheLastKey() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("abc")
        host.typeAtEnd("x", into: row)
        host.model.isShown = false
        try await waitUntil("the write on disappear") { !host.model.writes.isEmpty }
        #expect(lines(host) == ["abcx"])
    }

    /// Opening in rich mode, waiting and going to the background with no edit writes nothing.
    @Test func untouchedRichModeWritesNothing() async throws {
        let host = EditorWindow("# Title\r\n\r\nSome *text*\r\n<div>x</div>\r\n", mode: .rich)
        defer { host.close() }
        _ = try await host.waitForRichRow("Title")
        try await Task.sleep(for: EditorWindow.idleDelay * 3)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        host.model.mode = .source
        _ = try await host.waitForSourceTextView()
        host.model.isShown = false
        try await EditorWindow.settle()
        #expect(host.model.writes.isEmpty)
    }

    /// A new text from outside reloads rich mode.
    @Test func outsideChangeReloadsRichMode() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        _ = try await host.waitForRichRow("abc")
        host.model.text = "new text"
        _ = try await host.waitForRichRow("new text")
        #expect(host.model.writes.isEmpty)
    }

    /// Undo history belongs to one load: after a trip to source mode, rich mode starts with no undo.
    @Test func richUndoStartsEmptyAfterSourceMode() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("abc")
        host.typeAtEnd("x", into: row)
        host.model.mode = .source
        _ = try await host.waitForSourceTextView()
        host.model.mode = .rich
        let newRow = try await host.waitForRichRow("abcx")
        newRow.becomeFirstResponder()
        #expect(newRow.undoManager?.canUndo == false)
    }

    /// A new text from outside replaces an unsaved key. The idle save of the old text must not write it back.
    @Test func outsideChangeDuringAnUnsavedKeyIsNotOverwrittenByTheIdleSave() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("abc")
        host.typeAtEnd("x", into: row)
        host.model.text = "new"
        _ = try await host.waitForRichRow("new")
        try await Task.sleep(for: EditorWindow.idleDelay * 3)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        try await EditorWindow.settle()
        #expect(host.model.writes.isEmpty)
        #expect(host.model.text == "new")
    }
}
