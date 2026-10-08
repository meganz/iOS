@testable import MEGAMarkdownEditor
import Testing

@Suite struct RichChangePlanTests {
    /// The plan for the editor's last change, with the identities the list showed before it.
    /// `before` are the blocks the list showed. Without them, the changed rows keep their shape.
    private func plan(after editor: RichEditor, shown: [RichRowID], applied: Int, typedRow: Int? = nil,
                      oldCounts: [Int]? = nil, newCounts: [Int]? = nil, before: [RichBlock]? = nil) -> RichChangePlan {
        let change = editor.lastChange
        let oldRange = change?.oldRange ?? 0..<0
        let newRange = oldRange.lowerBound..<(oldRange.lowerBound + (change?.newCount ?? 0))
        // After a missed change the old range can lie past the rows the list shows.
        let oldIDs = oldRange.upperBound <= shown.count ? Array(shown[oldRange]) : []
        let newIDs = editor.rows[newRange].map(\.id)
        let newShapes = editor.rows[newRange].map { RichRowShape(block: $0.block) }
        let oldShapes = before.map { blocks in
            oldRange.upperBound <= blocks.count ? blocks[oldRange].map(RichRowShape.init(block:)) : []
        } ?? oldIDs.indices.map { newShapes.indices.contains($0) ? newShapes[$0] : .plain }
        return RichChangePlan.make(RichChangePlan.Input(
            appliedVersion: applied,
            version: editor.version,
            lastChange: change,
            typedRow: typedRow,
            oldIDs: oldIDs,
            newIDs: newIDs,
            oldItemCounts: oldCounts ?? oldIDs.map { _ in 1 },
            newItemCounts: newCounts ?? newIDs.map { _ in 1 },
            oldShapes: oldShapes,
            newShapes: newShapes
        ))
    }

    @Test func sameVersionIsASelectionChange() {
        var target = editor([paragraph("a"), paragraph("b")])
        let shown = target.rows.map(\.id)
        target.select(.caret(position(1, 1)))
        #expect(plan(after: target, shown: shown, applied: target.version) == .selectionOnly)
    }

    @Test func typingInARowIsAnOwnEdit() {
        var target = editor([paragraph("a"), paragraph("b")])
        let shown = target.rows.map(\.id)
        target.replaceText(inBlock: 1, range: 1..<1, with: "x")
        #expect(plan(after: target, shown: shown, applied: target.version - 1, typedRow: 1) == .ownEdit(row: 1))
    }

    /// The same key without a typing text view (for example a style toggle) reconfigures the row.
    @Test func rowChangeNotTypedIsAReplace() {
        var target = editor([paragraph("a"), paragraph("b")])
        let shown = target.rows.map(\.id)
        target.replaceText(inBlock: 1, range: 1..<1, with: "x")
        #expect(plan(after: target, shown: shown, applied: target.version - 1) == .replace(oldRows: 1..<2, newRowCount: 1, keptRows: 1))
    }

    /// After an own edit the list shows the new version, so the next change is one more and applies.
    @Test func changeAfterAnOwnEditApplies() {
        var target = editor([paragraph("ab")], caret: position(0, 2))
        var shown = target.rows.map(\.id)
        target.replaceText(inBlock: 0, range: 2..<2, with: "c")
        #expect(plan(after: target, shown: shown, applied: 0, typedRow: 0) == .ownEdit(row: 0))
        let applied = target.version
        shown = target.rows.map(\.id)
        // Enter at the end of a row adds the new row after it.
        target.insertParagraphBreak()
        #expect(plan(after: target, shown: shown, applied: applied) == .replace(oldRows: 1..<1, newRowCount: 1, keptRows: 0))
    }

    @Test func enterSplitsARowAndKeepsTheFirst() {
        var target = editor([paragraph("a"), paragraph("bc"), paragraph("d")], caret: position(1, 1))
        let shown = target.rows.map(\.id)
        target.insertParagraphBreak()
        #expect(plan(after: target, shown: shown, applied: target.version - 1) == .replace(oldRows: 1..<2, newRowCount: 2, keptRows: 1))
    }

    @Test func missedChangeReloadsAll() {
        var target = editor([paragraph("a")], caret: position(0, 1))
        let shown = target.rows.map(\.id)
        target.insertParagraphBreak()
        target.insertParagraphBreak()
        #expect(plan(after: target, shown: shown, applied: target.version - 2) == .reloadAll)
    }

    @Test func versionBehindTheListReloadsAll() {
        let target = editor([paragraph("a")])
        #expect(plan(after: target, shown: target.rows.map(\.id), applied: target.version + 1) == .reloadAll)
    }

    /// Undo puts back old identities. The list shows other identities there, so those rows are not kept.
    @Test func undoRestoringOldIdentitiesKeepsNoRow() {
        var target = editor([paragraph("a"), paragraph("bc")], caret: position(1, 1))
        target.insertParagraphBreak()
        target.deleteBackward()
        let shown = target.rows.map(\.id)
        let joined = target.version
        target.undo()
        let result = plan(after: target, shown: shown, applied: joined)
        guard case .replace(let oldRows, let newRowCount, let keptRows) = result else {
            Issue.record("not a replace: \(result)")
            return
        }
        #expect(newRowCount == oldRows.count + 1)
        let restored = target.rows[oldRows.lowerBound..<(oldRows.lowerBound + newRowCount)].map(\.id)
        let expectedKept = zip(shown[oldRows], restored).prefix { $0.0 == $0.1 }.count
        #expect(keptRows == expectedKept)
    }

    /// A kept raw row whose preview rows grew needs new items: it counts as replaced.
    @Test func rawRowWithANewPieceCountIsNotKept() {
        let id = RichRowID(value: 3)
        let input = RichChangePlan.Input(
            appliedVersion: 4, version: 5, lastChange: RichEditor.RowChange(oldRange: 2..<3, newCount: 1), typedRow: nil,
            oldIDs: [id], newIDs: [id], oldItemCounts: [2], newItemCounts: [3], oldShapes: [.plain], newShapes: [.plain]
        )
        #expect(RichChangePlan.make(input) == .replace(oldRows: 2..<3, newRowCount: 1, keptRows: 0))
    }

    @Test func mismatchedInputsReloadAll() {
        let input = RichChangePlan.Input(
            appliedVersion: 4, version: 5, lastChange: RichEditor.RowChange(oldRange: 2..<4, newCount: 1), typedRow: nil,
            oldIDs: [RichRowID(value: 1)], newIDs: [RichRowID(value: 1)], oldItemCounts: [1], newItemCounts: [1],
            oldShapes: [.plain], newShapes: [.plain]
        )
        #expect(RichChangePlan.make(input) == .reloadAll)
    }

    /// Enter in an empty list item or quote steps the row out in place: same id, one row. Its marker or bar must go.
    @Test(arguments: [
        [paragraph("a"), bullet("")],
        [paragraph("a"), task("")],
        [paragraph("a"), bullet("", indent: 0), paragraph("b")],
        [paragraph("a"), quote("")],
        [paragraph("a"), quote("", depth: 2)]
    ])
    func enterInAnEmptyListItemOrQuoteIsAReplace(blocks: [RichBlock]) {
        var target = editor(blocks, caret: position(1, 0))
        let before = target.rows.map(\.block)
        let shown = target.rows.map(\.id)
        target.replaceText(inBlock: 1, range: 0..<0, with: "\n")
        let result = plan(after: target, shown: shown, applied: target.version - 1, typedRow: 1, before: before)
        #expect(result == .replace(oldRows: 1..<2, newRowCount: 1, keptRows: 1), "plan \(result), rows \(target.rows.map(\.block))")
    }

    @Test func typingInAListItemAndAQuoteIsAnOwnEdit() {
        var target = editor([task("a"), quote("b")], caret: position(0, 1))
        let before = target.rows.map(\.block)
        let shown = target.rows.map(\.id)
        target.replaceText(inBlock: 0, range: 1..<1, with: "x")
        #expect(plan(after: target, shown: shown, applied: target.version - 1, typedRow: 0, before: before) == .ownEdit(row: 0))
        let applied = target.version
        target.replaceText(inBlock: 1, range: 1..<1, with: "y")
        #expect(plan(after: target, shown: target.rows.map(\.id), applied: applied, typedRow: 1, before: target.rows.map(\.block)) == .ownEdit(row: 1))
    }

    @Test func shapeIgnoresTextAndTaskState() {
        #expect(RichRowShape(block: task("a", checked: true)) == RichRowShape(block: task("b")))
        #expect(RichRowShape(block: bullet("a")) != RichRowShape(block: task("a")))
        #expect(RichRowShape(block: bullet("a")) != RichRowShape(block: bullet("a", indent: 1)))
        #expect(RichRowShape(block: quote("a")) != RichRowShape(block: quote("a", depth: 2)))
        #expect(RichRowShape(block: paragraph("a")) == .plain)
    }
}
