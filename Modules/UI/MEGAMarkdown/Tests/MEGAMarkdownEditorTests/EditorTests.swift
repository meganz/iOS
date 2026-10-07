@testable import MEGAMarkdownEditor
import Testing

@Suite("Editor typing and selection")
struct EditorTypingTests {
    @Test func keysInOneRowAreOneUndoStep() {
        var target = editor([paragraph("")])
        for (offset, letter) in ["a", "b", "c"].enumerated() {
            target.replaceText(inBlock: 0, range: offset..<offset, with: letter)
        }
        #expect(target.blocks == [paragraph("abc")])
        #expect(target.selection == .caret(position(0, 3)))
        target.undo()
        #expect(target.blocks == [paragraph("")])
        target.redo()
        #expect(target.blocks == [paragraph("abc")])
    }

    @Test func aPauseStartsANewUndoStep() {
        var target = editor([paragraph("")])
        target.replaceText(inBlock: 0, range: 0..<0, with: "a")
        target.endTypingBurst()
        target.replaceText(inBlock: 0, range: 1..<1, with: "b")
        target.undo()
        #expect(target.blocks == [paragraph("a")])
    }

    @Test func typingContinuesTheStyleBeforeTheCaret() {
        var target = editor([paragraph("bold", (0..<4, .bold))], caret: position(0, 4))
        #expect(target.typingStyles == [.bold])
        target.replaceText(inBlock: 0, range: 4..<4, with: "er")
        #expect(target.blocks == [paragraph("bolder", (0..<6, .bold))])
    }

    @Test func aStyleTurnedOffAtTheCaretStaysOffInsideAWord() {
        var target = editor([paragraph("bold", (0..<4, .bold))], caret: position(0, 2))
        target.toggleStyle(.bold)
        #expect(target.typingStyles.isEmpty)
        target.replaceText(inBlock: 0, range: 2..<2, with: "x")
        #expect(target.blocks == [paragraph("boxld", (0..<2, .bold), (3..<5, .bold))])
    }

    @Test func typingAfterALinkIsPlain() {
        var target = editor([paragraph("go", (0..<2, link("u")))], caret: position(0, 2))
        target.replaceText(inBlock: 0, range: 2..<2, with: "!")
        #expect(target.blocks == [paragraph("go!", (0..<2, link("u")))])
    }

    @Test func typedNewlinesSplitTheBlock() {
        var target = editor([bullet("ab")], caret: position(0, 1))
        target.insertText("x\ny\nz")
        #expect(target.blocks == [bullet("ax"), bullet("y"), bullet("zb")])
        #expect(target.selection == .caret(position(2, 1)))
        target.undo()
        #expect(target.blocks == [bullet("ab")])
    }

    @Test func enterReplacesTheSelection() {
        var target = editor([paragraph("abcd")])
        target.select(selection(position(0, 1), position(0, 3)))
        target.insertParagraphBreak()
        #expect(target.blocks == [paragraph("a"), paragraph("d")])
        #expect(target.selection == .caret(position(1, 0)))
    }

    @Test func backspaceDeletesAWholeCharacter() {
        var target = editor([paragraph("a👍🏽")], caret: position(0, 5))
        target.deleteBackward()
        #expect(target.blocks == [paragraph("a")])
        target.deleteBackward()
        target.deleteBackward()
        #expect(target.blocks == [paragraph("")])
    }

    @Test func backspaceAtTheStartJoinsBlocks() {
        var target = editor([paragraph("a"), paragraph("b")], caret: position(1, 0))
        target.deleteBackward()
        #expect(target.blocks == [paragraph("ab")])
        #expect(target.selection == .caret(position(0, 1)))
    }

    @Test func deleteAcrossBlocksJoinsTheEnds() {
        var target = editor([heading(1, "Head"), .thematicBreak, .codeBlock(language: nil, code: "x"), bullet("tail")])
        target.select(selection(position(0, 2), position(3, 2)))
        target.deleteBackward()
        #expect(target.blocks == [heading(1, "Heil")])
        #expect(target.selection == .caret(position(0, 2)))
    }

    @Test func childrenOfARemovedParentMoveUp() {
        var target = editor([bullet("a"), bullet("b", indent: 1), bullet("c", indent: 2)], caret: position(0, 0))
        target.deleteBackward()
        #expect(target.blocks == [paragraph("a"), bullet("b"), bullet("c", indent: 1)])
    }

    @Test func deletingEverythingLeavesAnEmptyParagraph() {
        var target = editor([.rawSource("| a |"), .thematicBreak])
        target.selectAll()
        target.deleteBackward()
        #expect(target.blocks == [paragraph("")])
    }

    @Test func unannouncedChangesFindTheirRange() {
        var target = editor([paragraph("aa")], caret: position(0, 1))
        target.didChangeText(inBlock: 0, to: "aaa", caret: 2)
        #expect(target.blocks == [paragraph("aaa")])
        #expect(RichEditor.editRange(old: "aa", new: "aaa", caret: 2).range == 1..<1)
        #expect(RichEditor.editRange(old: "abc", new: "aXc").range == 1..<2)
    }

    @Test func rowIdentitiesSurviveEdits() {
        var target = editor([paragraph("a"), paragraph("b"), paragraph("c")], caret: position(1, 1))
        let ids = target.rows.map(\.id)
        target.insertParagraphBreak()
        #expect(target.rows.map(\.id).prefix(2) == ids.prefix(2))
        #expect(target.rows.last?.id == ids.last)
        // "b" stays as it is. One new empty row goes after it.
        #expect(target.lastChange == RichEditor.RowChange(oldRange: 2..<2, newCount: 1))
        target.undo()
        #expect(target.rows.map(\.id) == ids)
    }

    @Test func undoPutsTheSelectionBack() {
        var target = editor([paragraph("abc")])
        target.select(selection(position(0, 0), position(0, 3)))
        target.toggleStyle(.italic)
        target.select(.caret(position(0, 1)))
        target.undo()
        #expect(target.blocks == [paragraph("abc")])
        #expect(target.selection == selection(position(0, 0), position(0, 3)))
    }

    @Test func typingAtADividerStartsAParagraph() {
        var after = editor([.thematicBreak], caret: position(0, 1))
        after.replaceText(inBlock: 0, range: 1..<1, with: "a")
        after.replaceText(inBlock: 1, range: 1..<1, with: "b")
        #expect(after.blocks == [.thematicBreak, paragraph("ab")])
        #expect(after.selection == .caret(position(1, 2)))
        // The new paragraph and its keys are one undo step.
        after.undo()
        #expect(after.blocks == [.thematicBreak])
        var before = editor([.rawSource("| a |")], caret: position(0, 0))
        before.insertText("x")
        #expect(before.blocks == [paragraph("x"), .rawSource("| a |")])
    }

    @Test func pasteAtARawBlockGoesBeforeOrAfterIt() {
        var target = editor([.rawSource("| a |")], caret: position(0, 1))
        target.paste(RichPasteContent(markdown: "# H"))
        #expect(target.blocks == [.rawSource("| a |"), heading(1, "H")])
        #expect(target.selection == .caret(position(1, 1)))
    }

    @Test func tapBelowTheLastBlock() {
        var text = editor([paragraph("ab")])
        text.placeCaretAtEnd()
        #expect(text.selection == .caret(position(0, 2)))
        var raw = editor([.rawSource("| a |")])
        raw.placeCaretAtEnd()
        #expect(raw.blocks == [.rawSource("| a |"), paragraph("")])
        #expect(raw.selection == .caret(position(1, 0)))
        var code = editor([.codeBlock(language: nil, code: "x")])
        code.placeCaretAtEnd()
        #expect(code.blocks == [.codeBlock(language: nil, code: "x"), paragraph("")])
        #expect(code.selection == .caret(position(1, 0)))
    }
}

@Suite("Editor formatting")
struct EditorFormattingTests {
    @Test func aStyleOverManyBlocks() {
        var target = editor([paragraph("ab"), .codeBlock(language: nil, code: "x"), bullet("cd")])
        target.select(selection(position(0, 1), position(2, 1)))
        target.toggleStyle(.bold)
        #expect(target.blocks == [paragraph("ab", (1..<2, .bold)), .codeBlock(language: nil, code: "x"), .listItem(RichListItem(isOrdered: false), text: rich("cd", (0..<1, .bold)))])
        #expect(target.activeStyles == [.bold])
        target.toggleStyle(.bold)
        #expect(target.blocks == [paragraph("ab"), .codeBlock(language: nil, code: "x"), bullet("cd")])
    }

    @Test func blockActionsKeepTheCaret() {
        var target = editor([paragraph("ab")], caret: position(0, 1))
        target.apply(.toggleTaskList)
        #expect(target.blocks == [task("ab")])
        #expect(target.selection == .caret(position(0, 1)))
        target.toggleCheckbox(at: 0)
        #expect(target.blocks == [task("ab", checked: true)])
        target.undo()
        target.undo()
        #expect(target.blocks == [paragraph("ab")])
    }

    @Test func selectionSummaryMatchesEveryRowsStyles() {
        let blocks: [RichBlock] = [
            paragraph("ab", (0..<2, .bold), (0..<1, .italic)), .codeBlock(language: nil, code: "x"),
            bullet(""), paragraph("cd", (0..<2, .bold))
        ]
        var target = editor(blocks)
        target.select(selection(position(0, 0), position(3, 2)))
        #expect(target.selectionSummary == RichSelectionSummary(activeStyles: [.bold], hasText: true))
        // A plain row ends the pass early. The result is still empty.
        var plain = editor([paragraph("ab", (0..<2, .bold)), paragraph("c"), paragraph("d", (0..<1, .bold))])
        plain.selectAll()
        #expect(plain.selectionSummary == RichSelectionSummary(activeStyles: [], hasText: true))
        var codeOnly = editor([.codeBlock(language: nil, code: "x"), .thematicBreak])
        codeOnly.selectAll()
        #expect(codeOnly.selectionSummary == RichSelectionSummary(activeStyles: [], hasText: false))
    }

    @Test func codeBlocksTakeNoStyle() {
        let target = editor([.codeBlock(language: nil, code: "x")])
        #expect(!target.canApply(.bold))
        #expect(target.activeStyles.isEmpty)
    }
}

@Suite("Editor links")
struct EditorLinkTests {
    @Test func aNewLinkOnASelection() throws {
        var target = editor([paragraph("see docs")])
        target.select(selection(position(0, 4), position(0, 8)))
        let linkTarget = try #require(target.linkTarget())
        #expect(target.linkDraft(for: linkTarget) == RichLinkDraft(url: "", text: "docs", isEditing: false))
        let saved = target.saveLink(linkTarget, urlText: "mega.nz", label: "docs")
        #expect(saved)
        #expect(target.blocks == [paragraph("see docs", (4..<8, link("mega.nz")))])
        #expect(target.selection == .caret(position(0, 8)))
    }

    @Test func aCaretInsideALinkEditsTheWholeLink() throws {
        var target = editor([paragraph("see docs", (4..<8, link("https://a")))], caret: position(0, 6))
        let linkTarget = try #require(target.linkTarget())
        #expect(linkTarget == RichLinkTarget(blockIndex: 0, range: 4..<8))
        #expect(target.linkDraft(for: linkTarget) == RichLinkDraft(url: "https://a", text: "docs", isEditing: true))
        target.saveLink(linkTarget, urlText: "https://b", label: "the docs")
        #expect(target.blocks == [paragraph("see the docs", (4..<12, link("https://b")))])
        target.removeLink(RichLinkTarget(blockIndex: 0, range: 4..<12))
        #expect(target.blocks == [paragraph("see the docs")])
    }

    @Test func anEmptyLabelUsesTheURL() throws {
        var target = editor([paragraph("")])
        let linkTarget = try #require(target.linkTarget())
        target.saveLink(linkTarget, urlText: "https://mega.nz", label: " ")
        #expect(target.blocks == [paragraph("https://mega.nz", (0..<15, link("https://mega.nz")))])
    }

    @Test func linkURLs() {
        #expect(RichLinkURL.destination(from: "www.google.com") == "www.google.com")
        #expect(RichLinkURL.destination(from: "https://a.b") == "https://a.b")
        #expect(RichLinkURL.destination(from: "mailto:a@b.co") == "mailto:a@b.co")
        #expect(RichLinkURL.destination(from: "localhost:8080") == "localhost:8080")
        #expect(RichLinkURL.destination(from: "javascript:alert(1)") == nil)
        #expect(RichLinkURL.destination(from: "JavaScript:alert(1)") == nil)
        #expect(RichLinkURL.destination(from: "a b") == nil)
        #expect(!RichLinkURL.canSave(urlText: "  "))
    }

    @Test func aStaleTargetChangesNothing() {
        var target = editor([paragraph("ab")])
        let saved = target.saveLink(RichLinkTarget(blockIndex: 3, range: 0..<1), urlText: "https://a", label: "x")
        #expect(!saved)
        #expect(target.blocks == [paragraph("ab")])
    }
}

@Suite("Editor export")
struct EditorExportTests {
    @Test func anUntouchedFileDoesNotExport() {
        var target = RichEditor(markdown: "* a\n* b\n")
        #expect(target.exportChanges() == nil)
        #expect(target.holds("* a\n* b\n"))
    }

    @Test func anEditExportsOnce() {
        var target = RichEditor(markdown: "# T\n")
        target.replaceText(inBlock: 0, range: 1..<1, with: "x")
        #expect(target.exportChanges() == "# Tx\n")
        #expect(target.exportChanges() == nil)
        #expect(target.holds("# Tx\n"))
    }

    @Test func undoBackToTheLoadedTextDoesNotExport() {
        var target = RichEditor(markdown: "a\n")
        target.replaceText(inBlock: 0, range: 1..<1, with: "b")
        target.undo()
        #expect(target.exportChanges() == nil)
    }

    @Test func aBackgroundExportOfAnOldVersionIsDropped() {
        var target = RichEditor(markdown: "a\n")
        target.replaceText(inBlock: 0, range: 1..<1, with: "b")
        let job = target.makeExportJob()
        target.replaceText(inBlock: 0, range: 2..<2, with: "c")
        #expect(target.finishExport(job.run()) == nil)
        #expect(target.finishExport(target.makeExportJob().run()) == "abc\n")
    }

    @Test func theFileFormatIsKept() {
        var target = RichEditor(markdown: "\u{FEFF}a\r\nb")
        target.replaceText(inBlock: 0, range: 1..<1, with: "x")
        #expect(target.exportChanges() == "\u{FEFF}ax\r\nb")
    }
}

@Suite("Limits")
struct LimitTests {
    @Test func richModeLimit() {
        #expect(RichTextLimit.allowsRichMode(String(repeating: "a", count: RichTextLimit.maxLength)))
        #expect(!RichTextLimit.allowsRichMode(String(repeating: "a", count: RichTextLimit.maxLength + 1)))
        // 4 UTF-8 bytes, 2 UTF-16 units each.
        #expect(RichTextLimit.allowsRichMode(String(repeating: "😀", count: RichTextLimit.maxLength / 2)))
    }

    @Test func sourceLimit() {
        #expect(SourceTextLimit.check("a\nb") == .editable)
        #expect(SourceTextLimit.check(String(repeating: "a", count: SourceTextLimit.maxLineLength + 1)) == .lineTooLong)
    }

    @Test func byteEquality() {
        #expect(!"\u{E9}".hasSameBytes(as: "e\u{301}"))
        #expect("abc".hasSameBytes(as: "abc"))
    }
}
