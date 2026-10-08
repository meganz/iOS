import Foundation
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. The whole editor: what the app lifecycle and the mode switch keep or drop.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct MarkdownEditorLifecycleTests {
    /// The save on background ends the typing burst only for the export. The undo history stays.
    @Test func undoStillWorksAfterBackgroundAndForeground() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("abc")
        host.typeAtEnd("x", into: row)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let undoManager = try #require(row.undoManager)
        #expect(undoManager.canUndo)
        undoManager.undo()
        _ = try await host.waitForRichRow("abc")
        #expect(undoManager.canRedo)
        undoManager.redo()
        _ = try await host.waitForRichRow("abcx")
    }

    /// The caret does not travel between modes. Each mode starts with its own caret, and no rich row has the keyboard.
    @Test func selectionIsNotCarriedAcrossModes() async throws {
        let host = EditorWindow("# Title\n\nSome text", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("Some text")
        row.becomeFirstResponder()
        row.selectedRange = NSRange(location: 4, length: 0)
        host.model.mode = .source
        let source = try await host.waitForSourceTextView()
        let sourceCaret = source.selectedRange
        #expect(sourceCaret.length == 0)
        #expect(sourceCaret.location != 4 + "# Title\n\n".utf16.count, "the source caret is the rich caret")
        host.model.mode = .rich
        _ = try await host.waitForRichRow("Some text")
        #expect(host.richTextViews.allSatisfy { !$0.isFirstResponder })
    }

    /// The editor has no handler for a memory warning or the return to the foreground, on purpose:
    /// the rows, the caret and the undo history stay, and the only write is the idle save of the key.
    @Test func memoryWarningAndForegroundChangeNothing() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("abc")
        host.typeAtEnd("x", into: row)
        let caret = row.selectedRange
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        try await waitUntil("the idle save") { !host.model.writes.isEmpty }
        try await Task.sleep(for: EditorWindow.idleDelay * 3)
        #expect(host.model.writes.count == 1)
        #expect(host.richTextViews.first === row)
        #expect(row.text == "abcx")
        #expect(row.selectedRange == caret)
        #expect(row.undoManager?.canUndo == true)
    }
}
