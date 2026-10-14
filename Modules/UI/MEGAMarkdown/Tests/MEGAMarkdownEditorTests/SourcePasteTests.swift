@testable import MEGAMarkdownEditor
import Testing
import UIKit

// A named pasteboard: reading the general one in a test waits for the paste permission.
@MainActor
@Suite(.serialized) struct SourcePasteTests {
    private func pasteboard() throws -> UIPasteboard {
        let pasteboard = try #require(UIPasteboard(name: UIPasteboard.Name("SourcePasteTests"), create: true))
        pasteboard.items = []
        return pasteboard
    }

    private func textView(_ text: String, pasteboard: UIPasteboard) -> SourceUITextView {
        let textView = SourceUITextView(usingTextLayoutManager: false)
        textView.text = text
        textView.pasteboard = pasteboard
        return textView
    }

    @Test func pasteInsertsTheMarkdownTypeAtTheCaret() throws {
        let pasteboard = try pasteboard()
        RichPasteboard.write(RichClipboardContent(plainText: "Title", markdown: "## Title"), to: pasteboard)
        let textView = textView("a\n", pasteboard: pasteboard)
        textView.selectedRange = NSRange(location: 2, length: 0)
        textView.paste(nil)
        #expect(textView.text == "a\n## Title")
    }

    @Test func pasteReplacesTheSelectionWithTheMarkdownType() throws {
        let pasteboard = try pasteboard()
        RichPasteboard.write(RichClipboardContent(plainText: "bold", markdown: "**bold**"), to: pasteboard)
        let textView = textView("one two three", pasteboard: pasteboard)
        textView.selectedRange = NSRange(location: 4, length: 3)
        textView.paste(nil)
        #expect(textView.text == "one **bold** three")
    }

    /// CommonMark reads no escapes inside a code block, so a code part pasted into a fence must stay the raw code.
    @Test(arguments: ["a*b*c", "<!-- x", "# not a heading", "[l](u)", "x_y_z"])
    func codePartPastedIntoASourceFenceKeepsTheCode(part: String) throws {
        let rich = editor([.codeBlock(language: nil, code: "x " + part + " y")])
        let range = selection(position(0, 2), position(0, 2 + part.utf16.count))
        let content = try #require(RichClipboard.content(of: rich.document, in: range))
        let pasteboard = try pasteboard()
        RichPasteboard.write(content, to: pasteboard)
        let textView = textView("```\n\n```", pasteboard: pasteboard)
        textView.selectedRange = NSRange(location: 4, length: 0)
        textView.paste(nil)
        let blocks = RichMarkdownConverter.document(from: textView.text ?? "").blocks
        #expect(blocks == [.codeBlock(language: nil, code: part)])
    }

    /// A whole rich copy pastes with its syntax: headings, list markers and bold.
    @Test func richCopyPastesWithItsMarkdownSyntax() throws {
        let pasteboard = try pasteboard()
        var editor = RichEditor(markdown: "## Title\n\n- **item**\n")
        editor.selectAll()
        let content = try #require(editor.copy())
        RichPasteboard.write(content, to: pasteboard)
        let textView = textView("", pasteboard: pasteboard)
        textView.paste(nil)
        #expect(textView.text == content.markdown)
        #expect(textView.text.contains("## Title"))
        #expect(textView.text.contains("**item**"))
    }
}
