import Foundation
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. The flusher writes the pending text to the binding at once.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct MarkdownEditorFlusherTests {
    @Test func flusherWritesPendingSourceEditAtOnce() async throws {
        let host = EditorWindow("# Title\n")
        defer { host.close() }
        let textView = try await host.waitForSourceTextView()
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: (textView.text as NSString).length, length: 0)
        textView.insertText("x")
        host.model.flusher.flush()
        #expect(host.model.writes == ["# Title\nx"])
    }

    @Test func flusherWritesPendingRichEditAtOnce() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        let row = try await host.waitForRichRow("abc")
        host.typeAtEnd("x", into: row)
        host.model.flusher.flush()
        #expect(host.model.writes.map { $0.trimmingCharacters(in: .newlines) } == ["abcx"])
    }

    @Test func flusherWithoutEditsWritesNothing() async throws {
        let host = EditorWindow("abc", mode: .rich)
        defer { host.close() }
        _ = try await host.waitForRichRow("abc")
        host.model.flusher.flush()
        #expect(host.model.writes.isEmpty)
    }
}
