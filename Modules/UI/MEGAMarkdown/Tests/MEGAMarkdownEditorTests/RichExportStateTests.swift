@testable import MEGAMarkdownEditor
import Testing

@Suite("Export state")
struct RichExportStateTests {
    private func state(loaded: String = "loaded", exported: String = "exported") -> RichExportState {
        RichExportState(loadedMarkdown: loaded, exported: exported, cache: InlineExportCache())
    }

    /// An opened file with the caret at its end. Unlike a new file, it has no change before the first edit.
    private func loadedFile(_ markdown: String) -> RichEditor {
        var target = RichEditor(markdown: markdown)
        target.select(.caret(position(0, 1)))
        return target
    }

    @Test func acceptingTheLastExportGivesNothing() {
        var target = state()
        #expect(target.accept("exported", cache: InlineExportCache(), version: 1) == nil)
        #expect(!target.hasGivenOutExport)
    }

    @Test func acceptingNewMarkdownGivesItOutOnce() {
        var target = state()
        #expect(target.accept("changed", cache: InlineExportCache(), version: 1) == "changed")
        #expect(target.hasGivenOutExport)
        #expect(target.lastExported == "changed")
        #expect(target.accept("changed", cache: InlineExportCache(), version: 2) == nil)
    }

    @Test func acceptingKeepsTheVersionEvenWhenNothingChanged() {
        var target = state()
        _ = target.accept("exported", cache: InlineExportCache(), version: 5)
        #expect(target.exportedVersion == 5)
    }

    @Test func holdsTheLoadedTextBeforeAnyExportIsGivenOut() {
        #expect(state().holds("loaded"))
        #expect(state().holds("exported"))
        #expect(!state().holds("other"))
    }

    @Test func loadedTextIsARevertAfterAnExportWasGivenOut() {
        var target = state()
        _ = target.accept("changed", cache: InlineExportCache(), version: 1)
        #expect(!target.holds("loaded"))
        #expect(target.holds("changed"))
    }

    @Test func editorHasNoUnexportedChangesAfterLoad() {
        let target = RichEditor(markdown: "a\n")
        #expect(!target.hasUnexportedChanges)
    }

    @Test func aNewFileWithContentExportsItsFirstText() {
        var target = RichEditor(newFile: RichDocument(blocks: [paragraph("Hello")]))
        #expect(target.hasUnexportedChanges)
        #expect(target.exportChanges() == "Hello\n")
        #expect(target.exportChanges() == nil)
    }

    @Test func aNewFileWithContentExportsItsFirstTextInTheBackground() {
        var target = RichEditor(newFile: RichDocument(blocks: [paragraph("Hello")]))
        #expect(target.finishExport(target.makeExportJob().run()) == "Hello\n")
    }

    @Test func anEmptyNewFileExportsNothing() {
        var target = RichEditor(newFile: RichDocument(blocks: []))
        #expect(target.exportChanges() == nil)
    }

    @Test func editorExportsAnEditOnce() {
        var target = loadedFile("a\n")
        target.insertText("b")
        #expect(target.hasUnexportedChanges)
        #expect(target.exportChanges() == "ab\n")
        #expect(!target.hasUnexportedChanges)
        #expect(target.exportChanges() == nil)
    }

    @Test func undoAfterAnExportExportsTheOldTextAgain() {
        var target = loadedFile("a\n")
        target.insertText("b")
        _ = target.exportChanges()
        target.undo()
        #expect(target.hasUnexportedChanges)
        #expect(target.exportChanges() == "a\n")
    }

    @Test func aBackgroundResultForTheCurrentVersionIsAccepted() {
        var target = editor([paragraph("a")], caret: position(0, 1))
        target.insertText("b")
        let result = target.makeExportJob().run()
        #expect(target.finishExport(result) == "ab\n")
        #expect(target.holds("ab\n"))
    }

    @Test func aBackgroundResultForAnOlderVersionIsDropped() {
        var target = loadedFile("a\n")
        target.insertText("b")
        let result = target.makeExportJob().run()
        target.insertText("c")
        #expect(target.finishExport(result) == nil)
        #expect(target.hasUnexportedChanges)
        #expect(target.exportChanges() == "abc\n")
    }

    @Test func undoingBackToTheStartOfANewFileStillExportsIt() {
        var target = RichEditor(newFile: RichDocument(blocks: [paragraph("a")]))
        target.select(.caret(position(0, 1)))
        target.insertText("b")
        target.undo()
        #expect(target.exportChanges() == "a\n")
    }

    @Test func undoingBackToTheStartOfAnEmptyNewFileExportsNothing() {
        var target = RichEditor(newFile: RichDocument(blocks: []))
        target.insertText("x")
        target.undo()
        #expect(target.exportChanges() == nil)
    }
}
