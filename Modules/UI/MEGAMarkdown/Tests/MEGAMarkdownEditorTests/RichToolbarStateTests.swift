import Foundation
import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Observation
import Testing

@Suite struct RichToolbarStateTests {
    private func state(_ blocks: [RichBlock], caret: RichPosition = position(0, 0)) -> RichToolbarState {
        RichToolbarState(editor: editor(blocks, caret: caret))
    }

    @Test func showsTheRowKind() {
        #expect(state([heading(2, "Title")]).headingLevel == 2)
        #expect(state([bullet("a")]).list == .bullet)
        #expect(state([ordered("a")]).list == .numbered)
        #expect(state([task("a")]).list == .task)
        #expect(state([quote("a")]).isQuote)
        let body = state([paragraph("a")])
        #expect(body.headingLevel == nil)
        #expect(body.list == nil)
        #expect(!body.isQuote)
        #expect(!body.canIndent)
    }

    @Test func showsTheStylesAtTheCaret() {
        let styled = state([paragraph("ab", (0..<2, .bold), (0..<2, link("https://mega.nz")))], caret: position(0, 1))
        #expect(styled.activeStyles == [.bold])
        #expect(styled.isLinkOn)
        #expect(styled.canStyle)
    }

    @Test func codeRowsTakeNoStyle() {
        #expect(!state([.codeBlock(language: nil, code: "x")]).canStyle)
        #expect(!state([.thematicBreak]).canStyle)
    }

    /// The screen shows 8 nesting levels. A row at the 8th level cannot go deeper.
    @Test func indentStopsAtTheVisibleNestingLimit() {
        let deepest = MarkdownRowChrome.maxVisibleNesting - 1
        let blocks = (0...deepest).map { bullet("item \($0)", indent: $0) } + [bullet("same", indent: deepest)]
        let oneLevelUp = (0..<deepest).map { bullet("item \($0)", indent: $0) } + [bullet("same", indent: deepest - 1)]
        #expect(state(oneLevelUp, caret: position(deepest, 0)).canIndent)
        let last = state(blocks, caret: position(deepest + 1, 0))
        #expect(!last.canIndent)
        #expect(last.canOutdent)
    }

    /// The buttons match what the model does: an item goes at most one level deeper than the item above.
    @Test func listIndentFollowsTheItemAbove() {
        let first = state([bullet("a"), bullet("b")])
        #expect(!first.canIndent)
        #expect(!first.canOutdent)
        let second = state([bullet("a"), bullet("b")], caret: position(1, 0))
        #expect(second.canIndent)
        #expect(!second.canOutdent)
        let deeper = state([bullet("a"), bullet("b", indent: 1)], caret: position(1, 0))
        #expect(!deeper.canIndent)
        #expect(deeper.canOutdent)
        #expect(!state([paragraph("a"), bullet("b")], caret: position(1, 0)).canIndent)
    }

    @Test func quoteIndentFollowsTheQuoteAbove() {
        let first = state([quote("a")])
        #expect(!first.canIndent)
        #expect(!first.canOutdent)
        let second = state([quote("a"), quote("b")], caret: position(1, 0))
        #expect(second.canIndent)
        #expect(!second.canOutdent)
        let deeper = state([quote("a"), quote("b", depth: 2)], caret: position(1, 0))
        #expect(!deeper.canIndent)
        #expect(deeper.canOutdent)
    }

    /// Each state the toolbar shows is what the model then does.
    @Test(arguments: [
        [bullet("a"), bullet("b")], [bullet("a"), bullet("b", indent: 1)], [paragraph("a"), bullet("b")],
        [quote("a"), quote("b")], [quote("a"), quote("b", depth: 2)], [paragraph("a"), quote("b")]
    ])
    func buttonsMatchTheModel(blocks: [RichBlock]) {
        let shown = state(blocks, caret: position(1, 0))
        var indented = editor(blocks, caret: position(1, 0))
        indented.apply(.indent)
        #expect(shown.canIndent == (indented.blocks != blocks))
        var outdented = editor(blocks, caret: position(1, 0))
        outdented.apply(.outdent)
        #expect(shown.canOutdent == (outdented.blocks != blocks))
    }

    @Test func decorationCountFollowsTheRowKind() {
        #expect(RichToolbarState.decorationCount(of: bullet("a", indent: 3)) == 4)
        #expect(RichToolbarState.decorationCount(of: quote("a", depth: 2)) == 2)
        #expect(RichToolbarState.decorationCount(of: paragraph("a")) == 0)
    }

    // MARK: - Link button

    /// The Link button needs text in one row. Its state must change with the selection, so the toolbar redraws.
    @Test func linkNeedsTextInOneRow() {
        let across = editor([paragraph("abc"), paragraph("def")])
        var editorAcross = across
        editorAcross.select(RichSelection(start: position(0, 1), end: position(1, 2)))
        #expect(!RichToolbarState(editor: editorAcross).canEditLink)
        var inOne = across
        inOne.select(.range(0..<2, inBlock: 0))
        #expect(RichToolbarState(editor: inOne).canEditLink)
    }

    @MainActor
    @Test(arguments: [true, false])
    func toolbarObserversHearWhenTheLinkStateChanges(startsInOneRow: Bool) {
        let model = RichEditorModel(editor: RichEditor(markdown: "abc\n\ndef\n"))
        let inOne = RichSelection.range(0..<2, inBlock: 0)
        let across = RichSelection(start: position(0, 1), end: position(1, 2))
        model.select(startsInOneRow ? inOne : across)
        let heard = HeardChange()
        withObservationTracking {
            _ = model.toolbar
        } onChange: {
            heard.set()
        }
        model.select(startsInOneRow ? across : inOne)
        #expect(heard.value)
    }
}

private final class HeardChange: @unchecked Sendable {
    private let lock = NSLock()
    private var stored = false

    func set() { lock.withLock { stored = true } }
    var value: Bool { lock.withLock { stored } }
}
