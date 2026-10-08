@testable import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing

@Suite struct RichChromeIndexTests {
    /// Markdown the editor holds without raw rows, with one preview row per block.
    /// Lists nest past the 8 visible levels, ordered numbers reach 9 digits, and some items are empty.
    private static let parityCases: [String] = [
        "- a\n  - b\n    1. c\n- d\n",
        "999999998. a\n999999999. b\n1000000000 c\n",
        "1. one\n   - inner\n2. two\n",
        "- [ ] a\n- [x] b\n- c\n- [ ] d\n",
        "1. [ ] ordered task\n2. [x] done\n",
        "> a\n> > b\n> > > c\n>\n> d\n",
        "> a\n\nText\n\n> b\n> > c\n",
        "- a\n1. b\n- c\n",
        "- a\n  - b\n  1. c\n",
        "- a\n-\n- b\n- [ ] \n- c\n\n  -\n",
        "# Title\n\nText\n\n- a\n- b\n\n> q\n\n```swift\nlet a = 1\n```\n\n---\n\n1. x\n",
        (0..<11).map { String(repeating: "  ", count: $0) + "- level \($0)" }.joined(separator: "\n") + "\n- back\n",
        String(repeating: "> ", count: 11) + "deep\n" + String(repeating: "> ", count: 9) + "less\n",
        "1. a\n   1. b\n      1. c\n         1. d\n2. e\n"
    ]

    @Test(arguments: parityCases)
    func chromeMatchesThePreview(markdown: String) throws {
        let editor = RichEditor(markdown: markdown)
        let blocks = editor.rows.map(\.block)
        let hasRaw = blocks.contains { $0.isRawSource }
        try #require(!hasRaw, "raw rows: \(blocks)")
        // The editor-mode parse keeps empty list items, like the editor. The viewer parse drops them.
        let parsed = try #require(CmarkParser.editorBlocks(MarkdownSourceText(markdown).body))
        let preview = PreviewRows.rows(for: parsed.blocks, maxWeight: 0).map(\.chrome)
        let index = RichChromeIndex(blocks: blocks, numbers: editor.orderedNumbers())
        try #require(index.count == preview.count, "rows \(blocks)")
        for row in 0..<preview.count {
            #expect(index[row] == preview[row], "row \(row): \(blocks[row])")
        }
    }

    /// After each edit the updated index equals one built from scratch.
    @Test func updatesMatchARebuild() {
        var target = editor([paragraph("a"), bullet("b"), bullet("c", indent: 1), paragraph("d"), quote("e"), paragraph("f")])
        var index = RichChromeIndex(blocks: target.blocks, numbers: target.orderedNumbers())
        let edits: [(inout RichEditor) -> Void] = [
            { $0.select(.caret(position(0, 1))); $0.insertParagraphBreak() },
            { $0.replaceText(inBlock: 1, range: 0..<0, with: "x") },
            { $0.select(.caret(position(3, 1))); $0.insertParagraphBreak() },
            { $0.select(.caret(position(5, 0))); $0.apply(.toggleOrderedList) },
            { $0.select(.caret(position(5, 0))); $0.apply(.indent) },
            { $0.select(.caret(position(6, 0))); $0.deleteBackward() },
            { $0.undo() },
            { $0.select(.caret(position(0, 0))); $0.apply(.toggleQuote) },
            { $0.select(.caret(position($0.rows.count - 1, 1))); $0.insertParagraphBreak() },
            { $0.select(.caret(position(2, 0))); $0.apply(.toggleBulletList) },
            { $0.select(.caret(position(0, 0))); $0.deleteBackward() },
            { $0.selectAll(); $0.deleteSelection() }
        ]
        for (step, edit) in edits.enumerated() {
            let version = target.version
            edit(&target)
            #expect(target.version != version, "step \(step) changed nothing")
            if target.version != version, let change = target.lastChange {
                index.apply(change, blocks: target.blocks)
            }
            #expect(index == RichChromeIndex(blocks: target.blocks, numbers: target.orderedNumbers()), "step \(step): \(target.blocks)")
        }
    }

    /// A new item renumbers the items after it, outside the change. Those rows are reported.
    @Test func renumberedRowsAreReported() {
        var target = editor([ordered("a"), ordered("b"), ordered("c")], caret: position(0, 1))
        var index = RichChromeIndex(blocks: target.blocks, numbers: target.orderedNumbers())
        target.insertParagraphBreak()
        guard let change = target.lastChange else {
            Issue.record("no change")
            return
        }
        #expect(index.apply(change, blocks: target.blocks) == [2, 3])
    }

    @Test func plainChangeKeepsTheLastRowGap() {
        var target = editor([paragraph("a"), paragraph("b")], caret: position(1, 1))
        var index = RichChromeIndex(blocks: target.blocks, numbers: target.orderedNumbers())
        target.insertParagraphBreak()
        if let change = target.lastChange { index.apply(change, blocks: target.blocks) }
        #expect(index == RichChromeIndex(blocks: target.blocks, numbers: target.orderedNumbers()))
    }
}
