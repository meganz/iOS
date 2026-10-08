@testable import MEGAMarkdownEditor
import Testing

@Suite("Enter, Backspace and block actions")
struct StructureEditingTests {
    private func split(_ blocks: [RichBlock], at caret: RichPosition) -> ([RichBlock], RichPosition) {
        let (document, position) = RichDocument(blocks: blocks).splitting(at: caret)
        return (document.blocks, position)
    }

    private func backspace(_ blocks: [RichBlock], at index: Int) -> ([RichBlock], RichPosition)? {
        RichDocument(blocks: blocks).backspacingAtStart(of: index).map { ($0.0.blocks, $0.1) }
    }

    private func apply(_ action: RichBlockAction, _ blocks: [RichBlock], _ indexes: ClosedRange<Int>) -> [RichBlock] {
        RichDocument(blocks: blocks).applying(action, to: indexes).blocks
    }

    // MARK: Enter

    @Test func enterSplitsTextAndKeepsStyles() {
        let (blocks, caret) = split([paragraph("hello", (0..<5, .bold))], at: position(0, 2))
        #expect(blocks == [paragraph("he", (0..<2, .bold)), paragraph("llo", (0..<3, .bold))])
        #expect(caret == position(1, 0))
    }

    @Test func enterContinuesListsAndQuotes() {
        #expect(split([task("ab", checked: true)], at: position(0, 2)).0 == [task("ab", checked: true), task("")])
        #expect(split([ordered("ab", start: 5)], at: position(0, 2)).0 == [ordered("ab", start: 5), ordered("")])
        #expect(split([quote("ab", depth: 2)], at: position(0, 1)).0 == [quote("a", depth: 2), quote("b", depth: 2)])
    }

    @Test func enterOnAnEmptyItemRemovesOneLevel() {
        #expect(split([bullet("", indent: 1)], at: position(0, 0)).0 == [bullet("")])
        #expect(split([bullet("")], at: position(0, 0)).0 == [paragraph("")])
        #expect(split([quote("", depth: 2)], at: position(0, 0)).0 == [quote("", depth: 1)])
    }

    @Test func enterAtTheStartPushesTheBlockDown() {
        let (blocks, caret) = split([ordered("a", start: 3)], at: position(0, 0))
        #expect(blocks == [ordered("", start: 3), ordered("a")])
        #expect(caret == position(1, 0))
        #expect(split([heading(1, "H")], at: position(0, 0)).0 == [paragraph(""), heading(1, "H")])
    }

    @Test func enterAtAHeadingEndStartsAParagraph() {
        #expect(split([heading(2, "H")], at: position(0, 1)).0 == [heading(2, "H"), paragraph("")])
        #expect(split([heading(2, "Ha")], at: position(0, 1)).0 == [heading(2, "H"), heading(2, "a")])
    }

    @Test func enterInCodeAddsALine() {
        let (blocks, caret) = split([.codeBlock(language: nil, code: "ab")], at: position(0, 1))
        #expect(blocks == [.codeBlock(language: nil, code: "a\nb")])
        #expect(caret == position(0, 2))
        #expect(split([.codeBlock(language: nil, code: "ab")], at: position(0, 2)).0 == [.codeBlock(language: nil, code: "ab\n")])
    }

    @Test func enterOnAnEmptyLastCodeLineLeavesTheBlock() {
        let (blocks, caret) = split([.codeBlock(language: "swift", code: "a\n")], at: position(0, 2))
        #expect(blocks == [.codeBlock(language: "swift", code: "a"), paragraph("")])
        #expect(caret == position(1, 0))
        // An empty line in the middle stays code.
        #expect(split([.codeBlock(language: nil, code: "a\n\nb")], at: position(0, 2)).0 == [.codeBlock(language: nil, code: "a\n\n\nb")])
    }

    @Test func enterAtADividerAddsAParagraphBeforeOrAfter() {
        #expect(split([.thematicBreak], at: position(0, 0)).0 == [paragraph(""), .thematicBreak])
        #expect(split([.thematicBreak], at: position(0, 1)).0 == [.thematicBreak, paragraph("")])
    }

    // MARK: Backspace

    @Test func backspaceRemovesStructureFirst() {
        #expect(backspace([bullet("a", indent: 1)], at: 0)?.0 == [bullet("a")])
        #expect(backspace([bullet("a")], at: 0)?.0 == [paragraph("a")])
        #expect(backspace([heading(1, "a")], at: 0)?.0 == [paragraph("a")])
        #expect(backspace([quote("a", depth: 2)], at: 0)?.0 == [quote("a")])
    }

    @Test func backspaceOnAnEmptyItemBelowAnItemJoinsTheItemAbove() {
        let result = backspace([bullet("ab"), bullet("")], at: 1)
        #expect(result?.0 == [bullet("ab")])
        #expect(result?.1 == RichPosition(blockIndex: 0, offset: 2))
        #expect(backspace([bullet("")], at: 0)?.0 == [paragraph("")])
    }

    @Test func backspaceJoinsAParagraphIntoTheBlockBefore() {
        let result = backspace([bullet("ab"), paragraph("cd", (0..<2, .bold))], at: 1)
        #expect(result?.0 == [.listItem(RichListItem(isOrdered: false), text: rich("abcd", (2..<4, .bold)))])
        #expect(result?.1 == position(0, 2))
    }

    @Test func backspaceDeletesADividerBefore() {
        #expect(backspace([paragraph("a"), .thematicBreak, paragraph("b")], at: 2)?.0 == [paragraph("a"), paragraph("b")])
    }

    @Test func backspaceDoesNothingAgainstCodeOrRaw() {
        #expect(backspace([.codeBlock(language: nil, code: "x"), paragraph("a")], at: 1) == nil)
        #expect(backspace([.rawSource("| a |"), paragraph("")], at: 1)?.0 == [.rawSource("| a |")])
        #expect(backspace([paragraph("a")], at: 0) == nil)
    }

    @Test func aStartNumberMovesToTheNextItemWhenTheFirstLeaves() {
        #expect(backspace([ordered("a", start: 5), ordered("b")], at: 0)?.0 == [paragraph("a"), ordered("b", start: 5)])
    }

    // MARK: Block actions

    @Test func headingLevels() {
        #expect(apply(.setHeading(3), [bullet("a")], 0...0) == [heading(3, "a")])
        #expect(apply(.setHeading(9), [paragraph("a")], 0...0) == [heading(6, "a")])
        #expect(apply(.setHeading(nil), [heading(2, "a")], 0...0) == [paragraph("a")])
    }

    @Test func listTogglesTurnOnAndOff() {
        #expect(apply(.toggleBulletList, [paragraph("a")], 0...0) == [bullet("a")])
        #expect(apply(.toggleBulletList, [bullet("a")], 0...0) == [paragraph("a")])
        #expect(apply(.toggleOrderedList, [bullet("a", indent: 1)], 0...0) == [ordered("a", indent: 1)])
        #expect(apply(.toggleTaskList, [paragraph("a")], 0...0) == [task("a")])
        #expect(apply(.toggleQuote, [paragraph("a")], 0...0) == [quote("a")])
    }

    @Test func theFirstSelectedBlockDecidesForAll() {
        #expect(apply(.toggleBulletList, [paragraph("a"), bullet("b"), .thematicBreak], 0...2) == [bullet("a"), bullet("b"), .thematicBreak])
        #expect(apply(.toggleBulletList, [bullet("a"), paragraph("b")], 0...1) == [paragraph("a"), paragraph("b")])
    }

    @Test func indentMovesChildrenAndNeedsAParent() {
        let blocks = [bullet("a"), bullet("b"), bullet("c", indent: 1)]
        #expect(apply(.indent, blocks, 1...1) == [bullet("a"), bullet("b", indent: 1), bullet("c", indent: 2)])
        #expect(apply(.indent, blocks, 0...0) == blocks)
        #expect(apply(.outdent, [bullet("a"), bullet("b", indent: 1), bullet("c", indent: 2)], 1...1) == blocks)
        #expect(apply(.outdent, blocks, 0...0) == blocks)
    }

    @Test func quoteDepthChanges() {
        #expect(apply(.indent, [quote("a"), quote("b")], 1...1) == [quote("a"), quote("b", depth: 2)])
        #expect(apply(.outdent, [quote("a", depth: 2)], 0...0) == [quote("a")])
    }

    @Test func checkbox() {
        #expect(RichDocument(blocks: [task("a")]).togglingCheckbox(at: 0).blocks == [task("a", checked: true)])
        #expect(RichDocument(blocks: [bullet("a")]).togglingCheckbox(at: 0).blocks == [bullet("a")])
    }

    // MARK: Ordered numbers

    @Test func orderedNumbersCountPerRun() {
        let blocks = [ordered("a", start: 3), bullet("x", indent: 1), ordered("b"), bullet("c"), ordered("d"), paragraph("p"), ordered("e")]
        #expect(RichDocument(blocks: blocks).orderedNumbers() == [3, nil, 4, nil, 1, nil, 1])
        #expect(RichDocument(blocks: blocks).orderedNumber(at: 2) == 4)
    }

    @Test func shownNumbersMatchTheExport() {
        let blocks = [ordered("a", start: 3), bullet("x", indent: 1), ordered("b"), ordered("c", indent: 1, start: 7), ordered("d", indent: 1)]
        let numbers = RichDocument(blocks: loadedBlocks(exportedBody(blocks))).orderedNumbers()
        #expect(numbers == RichDocument(blocks: blocks).orderedNumbers())
    }
}
