@testable import MEGAMarkdownEditor
import Testing
import UIKit
import UniformTypeIdentifiers

// A named pasteboard: reading the general one in a test waits for the paste permission.
@MainActor
@Suite(.serialized) struct RichPasteboardTests {
    private func pasteboard() throws -> UIPasteboard {
        let pasteboard = try #require(UIPasteboard(name: UIPasteboard.Name("RichPasteboardTests"), create: true))
        pasteboard.items = []
        return pasteboard
    }

    @Test func copyWritesBothTypesInOneItem() throws {
        let pasteboard = try pasteboard()
        RichPasteboard.write(RichClipboardContent(plainText: "bold", markdown: "**bold**"), to: pasteboard)
        #expect(pasteboard.numberOfItems == 1)
        #expect(pasteboard.string == "bold")
        let markdown = pasteboard.data(forPasteboardType: RichClipboardContent.markdownType).flatMap { String(data: $0, encoding: .utf8) }
        #expect(markdown == "**bold**")
    }

    /// The model picks Markdown or plain text for the row it pastes into, so a read gives both.
    @Test func readGivesBothTypesOfOneCopy() throws {
        let pasteboard = try pasteboard()
        RichPasteboard.write(RichClipboardContent(plainText: "bold", markdown: "**bold**"), to: pasteboard)
        #expect(RichPasteboard.read(from: pasteboard) == RichPasteContent(markdown: "**bold**", plainText: "bold"))
        #expect(RichPasteboard.canPaste(from: pasteboard))
    }

    /// A copy of rich text pastes into a code block as plain text, without Markdown marks.
    @Test func copyOfBoldTextPastesIntoCodeWithoutMarks() throws {
        let pasteboard = try pasteboard()
        var source = RichEditor(markdown: "**bold** text\n")
        source.select(.range(0..<4, inBlock: 0))
        RichPasteboard.write(try #require(source.copy()), to: pasteboard)
        var target = RichEditor(markdown: "```\n\n```\n")
        target.select(.caret(RichPosition(blockIndex: 0, offset: 0)))
        target.paste(try #require(RichPasteboard.read(from: pasteboard)))
        #expect(target.rows[0].block.codeText == "bold")
    }

    /// A copy of a whole code block pastes into another code block without its fences.
    @Test func copyOfCodeBlockPastesIntoCodeWithoutFences() throws {
        let pasteboard = try pasteboard()
        var source = RichEditor(markdown: "```\nlet a = 1\n```\n")
        source.select(.range(0..<9, inBlock: 0))
        RichPasteboard.write(try #require(source.copy()), to: pasteboard)
        var target = RichEditor(markdown: "```\n\n```\n")
        target.select(.caret(RichPosition(blockIndex: 0, offset: 0)))
        target.paste(try #require(RichPasteboard.read(from: pasteboard)))
        #expect(target.rows[0].block.codeText == "let a = 1")
    }

    @Test func readFallsBackToPlainText() throws {
        let pasteboard = try pasteboard()
        pasteboard.string = "**from another app**"
        #expect(RichPasteboard.read(from: pasteboard) == RichPasteContent(plainText: "**from another app**"))
    }

    @Test func emptyPasteboardReadsNothing() throws {
        let pasteboard = try pasteboard()
        #expect(RichPasteboard.read(from: pasteboard) == nil)
        #expect(!RichPasteboard.canPaste(from: pasteboard))
    }

    /// What a copy writes pastes back as the same rows.
    @Test func copyThenPasteGivesTheSameRows() throws {
        let pasteboard = try pasteboard()
        var source = editor([heading(2, "Title"), bullet("a", indent: 0), paragraph("x", (0..<1, .bold))])
        source.selectAll()
        let content = try #require(source.copy())
        RichPasteboard.write(content, to: pasteboard)
        var target = editor([paragraph("")])
        target.paste(try #require(RichPasteboard.read(from: pasteboard)))
        #expect(target.blocks == [heading(2, "Title"), bullet("a", indent: 0), paragraph("x", (0..<1, .bold))])
    }
}
