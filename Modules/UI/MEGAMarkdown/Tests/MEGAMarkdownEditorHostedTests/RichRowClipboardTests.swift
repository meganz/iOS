import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. Copy, cut, paste and the edit menu inside one row, on a named pasteboard.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichRowClipboardTests {
    private func focused(_ harness: RichListHarness, row: Int, range: NSRange) async throws -> RichTextView {
        harness.model.setFocused(true)
        harness.model.select(.range(range.location..<NSMaxRange(range), inBlock: row))
        try await harness.waitUntil { harness.focusedTextView != nil }
        let textView = try #require(harness.focusedTextView)
        let pasteboard = try #require(UIPasteboard(name: UIPasteboard.Name("RichRowClipboardTests"), create: true))
        pasteboard.items = []
        textView.pasteboard = pasteboard
        return textView
    }

    private func markdown(on pasteboard: UIPasteboard) -> String? {
        pasteboard.data(forPasteboardType: RichClipboardContent.markdownType).flatMap { String(data: $0, encoding: .utf8) }
    }

    @Test func copyWritesTextAndMarkdown() async throws {
        let harness = try RichListHarness("a **bold** b")
        defer { harness.close() }
        let textView = try await focused(harness, row: 0, range: NSRange(location: 2, length: 4))
        textView.copy(nil)
        #expect(textView.pasteboard.string == "bold")
        #expect(markdown(on: textView.pasteboard) == "**bold**")
        #expect(textView.pasteboard.numberOfItems == 1)
    }

    @Test func cutRemovesTheTextAndWritesIt() async throws {
        let harness = try RichListHarness("abcd")
        defer { harness.close() }
        let textView = try await focused(harness, row: 0, range: NSRange(location: 1, length: 2))
        textView.cut(nil)
        try await harness.waitUntil { harness.focusedTextView?.text == "ad" }
        #expect(textView.pasteboard.string == "bc")
        #expect(harness.model.row(at: 0).block == paragraph("ad"))
    }

    /// Markdown pastes as rows with styles, through the model. It is never typed as plain lines.
    @Test func pasteReadsTheMarkdownIntoTheModel() async throws {
        let harness = try RichListHarness("x")
        defer { harness.close() }
        let textView = try await focused(harness, row: 0, range: NSRange(location: 1, length: 0))
        RichPasteboard.write(RichClipboardContent(plainText: "b\nitem", markdown: "**b**\n\n- item"), to: textView.pasteboard)
        #expect(textView.canPerformAction(#selector(RichTextView.paste(_:)), withSender: nil))
        textView.paste(nil)
        try await harness.settle()
        #expect(harness.model.rowCount == 2)
        #expect(harness.model.row(at: 0).block == paragraph("xb", (1..<2, .bold)))
        #expect(harness.model.row(at: 1).block == bullet("item"))
        #expect(harness.textView(row: 0)?.text == "xb")
    }

    /// A paste inside one line stays in the row: same row, caret after the pasted text, keyboard kept.
    @Test func oneLinePasteStaysInTheRow() async throws {
        let harness = try RichListHarness("ad\n\nnext")
        defer { harness.close() }
        let textView = try await focused(harness, row: 0, range: NSRange(location: 1, length: 0))
        textView.pasteboard.string = "bc"
        textView.paste(nil)
        try await harness.waitUntil { harness.focusedTextView?.text == "abcd" }
        #expect(harness.model.rowCount == 2)
        #expect(harness.focusedTextView?.selectedRange == NSRange(location: 3, length: 0))
    }

    @Test func pasteIsOffWithAnEmptyPasteboard() async throws {
        let harness = try RichListHarness("x")
        defer { harness.close() }
        let textView = try await focused(harness, row: 0, range: NSRange(location: 1, length: 0))
        #expect(!textView.canPerformAction(#selector(RichTextView.paste(_:)), withSender: nil))
    }

    @Test func editMenuOffersLinkForSelectedText() async throws {
        let harness = try RichListHarness("go here")
        defer { harness.close() }
        let textView = try await focused(harness, row: 0, range: NSRange(location: 3, length: 4))
        let coordinator = try #require(textView.delegate as? RichTextRow.Coordinator)
        let menu = try #require(coordinator.textView(textView, editMenuForTextIn: textView.selectedRange, suggestedActions: []))
        let link = try #require(menu.children.last as? UIAction)
        #expect(link.title == "Link")
        link.performWithSender(nil, target: nil)
        #expect(harness.model.linkDialog?.draft.text == "here")
    }

    @Test func editMenuIsTheSystemMenuForACaret() async throws {
        let harness = try RichListHarness("go here")
        defer { harness.close() }
        let textView = try await focused(harness, row: 0, range: NSRange(location: 3, length: 0))
        let coordinator = try #require(textView.delegate as? RichTextRow.Coordinator)
        #expect(coordinator.textView(textView, editMenuForTextIn: textView.selectedRange, suggestedActions: []) == nil)
    }
}
