import CoreGraphics
import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing

@Suite("Selection geometry")
struct SelectionGeometryTests {
    private let row = CGRect(x: 0, y: 100, width: 300, height: 50)

    @Test func dragInsideTheRowOrItsMarginKeepsTheNativeSelection() {
        #expect(!SelectionGeometry.leftRow(CGPoint(x: 10, y: 92), rowFrame: row))
        #expect(!SelectionGeometry.leftRow(CGPoint(x: 10, y: 125), rowFrame: row))
        #expect(!SelectionGeometry.leftRow(CGPoint(x: 10, y: 158), rowFrame: row))
    }

    @Test func dragPastTheMarginTakesOver() {
        #expect(SelectionGeometry.leftRow(CGPoint(x: 10, y: 91.9), rowFrame: row))
        #expect(SelectionGeometry.leftRow(CGPoint(x: 10, y: 158.1), rowFrame: row))
    }

    @Test func nearerCaretIsTheGrabbedEnd() {
        let start = CGRect(x: 59, y: 233, width: 2, height: 26)
        let end = CGRect(x: 215, y: 365, width: 2, height: 26)
        #expect(SelectionGeometry.grabsEnd(touch: CGPoint(x: 216, y: 390), startCaret: start, endCaret: end))
        #expect(!SelectionGeometry.grabsEnd(touch: CGPoint(x: 59, y: 230), startCaret: start, endCaret: end))
    }

    @Test func rightToLeftRowUsesTheNearerCaretToo() {
        // In a right-to-left line the start caret is on the right.
        let start = CGRect(x: 300, y: 100, width: 2, height: 26)
        let end = CGRect(x: 120, y: 100, width: 2, height: 26)
        #expect(SelectionGeometry.grabsEnd(touch: CGPoint(x: 125, y: 120), startCaret: start, endCaret: end))
        #expect(!SelectionGeometry.grabsEnd(touch: CGPoint(x: 295, y: 95), startCaret: start, endCaret: end))
    }

    @Test func equalDistancePicksTheEnd() {
        let start = CGRect(x: 0, y: 0, width: 2, height: 20)
        let end = CGRect(x: 100, y: 0, width: 2, height: 20)
        #expect(SelectionGeometry.grabsEnd(touch: CGPoint(x: 51, y: 10), startCaret: start, endCaret: end))
    }

    @Test(arguments: [
        (CGFloat(300), CGFloat(0)),      // middle: no scroll
        (CGFloat(546), CGFloat(0)),      // zone edge (600 - 54)
        (CGFloat(573), CGFloat(750)),    // half way into the bottom zone
        (CGFloat(600), CGFloat(1_500)),  // bottom edge
        (CGFloat(700), CGFloat(1_500)),  // below the edge: capped
        (CGFloat(27), CGFloat(-750)),    // half way into the top zone
        (CGFloat(-20), CGFloat(-1_500))  // above the top: capped
    ])
    func autoscrollSpeedGrowsWithDepthInTheZone(fingerY: CGFloat, expected: CGFloat) {
        #expect(SelectionGeometry.autoscrollSpeed(fingerY: fingerY, visibleTop: 0, visibleBottom: 600) == expected)
    }

    @Test func shortListSplitsTheZones() {
        // 60 pt visible: each zone is 30 pt, so the middle does not scroll.
        #expect(SelectionGeometry.autoscrollSpeed(fingerY: 30, visibleTop: 0, visibleBottom: 60) == 0)
        #expect(SelectionGeometry.autoscrollSpeed(fingerY: 60, visibleTop: 0, visibleBottom: 60) == 1_500)
    }

    @Test func handleZonesReachTowardTheirKnobs() {
        let caret = CGRect(x: 100, y: 100, width: 2, height: 20)
        let start = SelectionGeometry.handleZone(caret: caret, isStart: true)
        let end = SelectionGeometry.handleZone(caret: caret, isStart: false)
        #expect(start == CGRect(x: 78, y: 80, width: 46, height: 48))
        #expect(end == CGRect(x: 78, y: 92, width: 46, height: 48))
    }

    @Test func shortStillTouchIsATap() {
        #expect(SelectionGeometry.isTap(from: .zero, to: CGPoint(x: 6, y: 8), duration: 0.2, listPanBegan: false))
    }

    @Test func scrollLongPressOrMoveIsNotATap() {
        #expect(!SelectionGeometry.isTap(from: .zero, to: CGPoint(x: 0, y: 2), duration: 0.2, listPanBegan: true))
        #expect(!SelectionGeometry.isTap(from: .zero, to: .zero, duration: 0.5, listPanBegan: false))
        #expect(!SelectionGeometry.isTap(from: .zero, to: CGPoint(x: 0, y: 10.1), duration: 0.2, listPanBegan: false))
    }

    @Test func atomicRowSplitsAtItsMiddle() {
        #expect(SelectionGeometry.offset(y: 124, frame: row, length: 1) == 0)
        #expect(SelectionGeometry.offset(y: 125, frame: row, length: 1) == 1)
    }

    @Test func rowWithoutCellSnapsToStartOrEnd() {
        #expect(SelectionGeometry.offset(y: 110, frame: row, length: 42) == 0)
        #expect(SelectionGeometry.offset(y: 140, frame: row, length: 42) == 42)
    }
}

@Suite("Cross-block selection")
struct CrossBlockSelectionTests {
    private let early = RichPosition(blockIndex: 2, offset: 5)
    private let late = RichPosition(blockIndex: 4, offset: 1)

    @Test func rangeIsOrderedWhateverTheDirection() {
        let backwards = CrossBlockSelection(anchor: late, head: early)
        #expect(backwards.range.start == early)
        #expect(backwards.range.end == late)
    }

    @Test func grabbingTheStartMakesItTheHead() {
        let selection = CrossBlockSelection(anchor: early, head: late).grabbing(start: true)
        #expect(selection == CrossBlockSelection(anchor: late, head: early))
    }

    @Test func grabbingTheEndMakesItTheHead() {
        let selection = CrossBlockSelection(anchor: late, head: early).grabbing(start: false)
        #expect(selection == CrossBlockSelection(anchor: early, head: late))
    }

    @Test func headGrowsToTheFarEdgeOfTheNextRow() {
        let lengths = [3, 5, 7, 9]
        let selection = CrossBlockSelection(anchor: RichPosition(blockIndex: 0, offset: 2), head: RichPosition(blockIndex: 1, offset: 5))
        let down = selection.movingHead(down: true, rowCount: 4) { lengths[$0] }
        #expect(down?.head == RichPosition(blockIndex: 2, offset: 7))
        let up = selection.movingHead(down: false, rowCount: 4) { lengths[$0] }
        #expect(up?.head == RichPosition(blockIndex: 0, offset: 3))
    }

    @Test func backwardHeadShrinksToTheNearEdge() {
        let lengths = [3, 5, 7, 9]
        let selection = CrossBlockSelection(anchor: RichPosition(blockIndex: 3, offset: 4), head: RichPosition(blockIndex: 1, offset: 0))
        #expect(selection.movingHead(down: true, rowCount: 4) { lengths[$0] }?.head == RichPosition(blockIndex: 2, offset: 0))
        #expect(selection.movingHead(down: false, rowCount: 4) { lengths[$0] }?.head == RichPosition(blockIndex: 0, offset: 0))
    }

    @Test func headStopsAtTheFirstAndLastRow() {
        let first = CrossBlockSelection(anchor: RichPosition(blockIndex: 1, offset: 0), head: RichPosition(blockIndex: 0, offset: 0))
        #expect(first.movingHead(down: false, rowCount: 2) { _ in 1 } == nil)
        let last = CrossBlockSelection(anchor: RichPosition(blockIndex: 0, offset: 0), head: RichPosition(blockIndex: 1, offset: 1))
        #expect(last.movingHead(down: true, rowCount: 2) { _ in 1 } == nil)
    }
}
