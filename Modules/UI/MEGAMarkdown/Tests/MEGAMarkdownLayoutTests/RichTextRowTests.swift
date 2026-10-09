import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// One editable row in a window, typed into like a keyboard. The row has no focus.
// Tests that need the focus are in `RichTextRowFocusTests` of `MEGAMarkdownEditorHostedTests`.
@MainActor
struct RichTextRowTests {
    private func textView(_ harness: RichTextRowHarness, caret: Int) throws -> RichTextView {
        let textView = try #require(harness.textView)
        textView.selectedRange = NSRange(location: caret, length: 0)
        return textView
    }

    @Test func showsTheModelText() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("ab cd", (0..<2, .bold))])
        defer { harness.close() }
        let textView = try #require(harness.textView)
        #expect(textView.text == "ab cd")
        let font = try #require(textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
        #expect(textView.textLayoutManager == nil)
        #expect(textView.layoutManager is InlineCodeLayoutManager)
    }

    /// A key reaches the model as one typing change of this row. The caret move it makes is not a select().
    @Test func typingReachesTheModel() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abc")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 3)
        harness.changes = []
        harness.type("x", into: textView)
        #expect(harness.model.row(at: 0).block == paragraph("abcx"))
        #expect(harness.changes == [.typing(row: 0)])
        #expect(harness.model.selection == .caret(position(0, 4)))
    }

    /// A keyboard announced one range and changed another of the same length. The model ends with the view's bytes.
    @Test func editAtAnotherRangeThanAnnouncedEndsWithEqualBytes() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abcd")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 4)
        _ = textView.delegate?.textView?(textView, shouldChangeTextIn: NSRange(location: 0, length: 0), replacementText: "x")
        textView.insertText("x")
        #expect(textView.text == "abcdx")
        #expect(harness.model.row(at: 0).block == paragraph("abcdx"))
    }

    @Test func enterSplitsTheRowInTheModel() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abcd")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 2)
        harness.type("\n", into: textView)
        #expect(harness.model.rowCount == 2)
        #expect(harness.model.row(at: 1).block == paragraph("cd"))
        // The view never keeps a line break: the list shows the new row.
        #expect(textView.text == "abcd")
    }

    /// A text replacement with a line break replaces the shortcut before the caret, not the caret.
    @Test func lineBreakGoesToTheAnnouncedRange() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abc omw")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 7)
        let allowed = textView.delegate?.textView?(textView, shouldChangeTextIn: NSRange(location: 4, length: 3), replacementText: "on my\nway")
        #expect(allowed == false)
        #expect(harness.model.rowCount == 2)
        #expect(harness.model.row(at: 0).block == paragraph("abc on my"))
        #expect(harness.model.row(at: 1).block == paragraph("way"))
    }

    /// Dictation and code insert text without asking the delegate. The model still splits the row,
    /// and the row's next input takes the line break out of the view.
    @Test func lineBreakWithoutTheDelegateStillSplits() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abcd")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 2)
        textView.insertText("\n")
        #expect(harness.model.rowCount == 2)
        harness.reconfigure()
        harness.flushLayout()
        #expect(textView.text == "ab")
    }

    @Test func enterOnAnEmptyLastCodeLineLeavesTheBlock() throws {
        let harness = RichTextRowHarness(blocks: [.codeBlock(language: nil, code: "a\n")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 2)
        harness.type("\n", into: textView)
        #expect(harness.model.rowCount == 2)
        #expect(harness.model.row(at: 0).block == .codeBlock(language: nil, code: "a"))
    }

    @Test func backspaceAtTheStartRemovesStructure() throws {
        let harness = RichTextRowHarness(blocks: [heading(2, "Title")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 0)
        textView.deleteBackward()
        #expect(harness.model.row(at: 0).block == paragraph("Title"))
    }

    @Test func tabIndentsAListItem() throws {
        let harness = RichTextRowHarness(blocks: [bullet("a"), bullet("b")], row: 1)
        defer { harness.close() }
        let textView = try textView(harness, caret: 0)
        harness.model.select(.caret(position(1, 0)))
        let tab = try #require(textView.keyCommands?.first { $0.input == "\t" && $0.modifierFlags.isEmpty })
        #expect(tab.wantsPriorityOverSystemBehavior)
        textView.perform(tab.action)
        #expect(harness.model.row(at: 1).block == bullet("b", indent: 1))
    }

    /// An input the view already holds, or an older one, never overwrites a typed key.
    @Test func olderInputDoesNotOverwriteTypedText() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abc")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 3)
        harness.type("x", into: textView)
        // SwiftUI draws the row again with the input it had: version 0, text "abc".
        harness.input.block = paragraph("abc")
        harness.flushLayout()
        #expect(textView.text == "abcx")
    }

    /// Undo gives a newer input with the old text. The view takes it.
    @Test func newerInputReplacesTheText() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abc")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 3)
        harness.type("x", into: textView)
        textView.undoManager?.undo()
        harness.reconfigure()
        harness.flushLayout()
        #expect(textView.text == "abc")
    }

    /// Text the input method still owns is never replaced. The newer input is written when it ends.
    @Test func markedTextIsNotOverwritten() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abc")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 3)
        textView.setMarkedText("か", selectedRange: NSRange(location: 1, length: 0))
        #expect(textView.undoManager == nil)
        harness.input.block = paragraph("other")
        harness.input.version += 5
        harness.flushLayout()
        #expect(textView.text == "abcか")
        textView.unmarkText()
        harness.flushLayout()
        #expect(textView.markedTextRange == nil)
        #expect(textView.undoManager === harness.modelUndoManager)
    }

    @Test func modelSelectionIsNotReportedBack() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("abcd")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 0)
        harness.changes = []
        textView.setSelectionFromModel(NSRange(location: 2, length: 0))
        #expect(harness.changes.isEmpty)
        #expect(textView.selectedRange == NSRange(location: 2, length: 0))
    }

    /// The list is told only when the text gets a new line, not on every key.
    @Test func heightChangeIsReportedOncePerNewLine() throws {
        let harness = RichTextRowHarness(blocks: [paragraph("")])
        defer { harness.close() }
        let textView = try textView(harness, caret: 0)
        harness.type("a", into: textView)
        let afterFirst = harness.heightChanges
        for _ in 0..<5 { harness.type("a", into: textView) }
        #expect(harness.heightChanges == afterFirst)
        harness.type(String(repeating: "word ", count: 30), into: textView)
        #expect(harness.heightChanges == afterFirst + 1)
    }

    @Test func arrowsLeaveOnlyAtTheEdges() throws {
        let harness = RichTextRowHarness(blocks: [paragraph(String(repeating: "word ", count: 30))])
        defer { harness.close() }
        let textView = try textView(harness, caret: 0)
        let upInputs = { textView.keyCommands?.filter { $0.input == UIKeyCommand.inputUpArrow && $0.modifierFlags.isEmpty } ?? [] }
        let downInputs = { textView.keyCommands?.filter { $0.input == UIKeyCommand.inputDownArrow && $0.modifierFlags.isEmpty } ?? [] }
        #expect(upInputs().count == 1)
        #expect(downInputs().isEmpty)
        let up = try #require(upInputs().first)
        textView.perform(up.action)
        #expect(harness.leftThrough == [.up])
        textView.selectedRange = NSRange(location: (textView.text as NSString).length, length: 0)
        #expect(upInputs().isEmpty)
        #expect(downInputs().count == 1)
    }

    @Test func codeRowsTypePlainText() throws {
        let harness = RichTextRowHarness(blocks: [.codeBlock(language: "swift", code: "let a")])
        defer { harness.close() }
        let textView = try #require(harness.textView)
        #expect(textView.autocorrectionType == .no)
        #expect(textView.smartQuotesType == .no)
        #expect(textView.semanticContentAttribute == .forceLeftToRight)
    }
}
