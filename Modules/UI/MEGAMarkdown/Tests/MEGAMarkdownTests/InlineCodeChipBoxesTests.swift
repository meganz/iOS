import CoreGraphics
@testable import MEGAMarkdown
import Testing

/// The chip box rule: 3 pt padding, but at least 2 pt to the word or chip next to it.
@Suite struct InlineCodeChipBoxesTests {
    /// Glyphs of one line, 10 pt high, from (x, width) pairs.
    private func glyph(_ x: CGFloat, _ width: CGFloat, chip: Bool = false, blank: Bool = false) -> ChipLineGlyph {
        ChipLineGlyph(rect: CGRect(x: x, y: 0, width: width, height: 10), isChip: chip, isBlank: blank)
    }

    @Test func aChipAloneGrowsByThePadding() throws {
        let box = try #require(InlineCodeChipBoxes.boxes([glyph(10, 8, chip: true), glyph(18, 8, chip: true)]).first)
        #expect(box.minX == 7)
        #expect(box.maxX == 29)
    }

    /// The box is as tall as asked and centered on the glyphs, so a chip can be taller than the font.
    @Test func aBoxWithAHeightIsCenteredOnTheGlyphs() throws {
        let box = try #require(InlineCodeChipBoxes.boxes([glyph(10, 8, chip: true)], height: 16).first)
        #expect(box.height == 16)
        #expect(box.midY == 5)
    }

    /// At the start of a line the box reaches past the text edge. The text view keeps room for it.
    @Test func aBoxAtTheLineStartReachesPastTheEdge() throws {
        let box = try #require(InlineCodeChipBoxes.boxes([glyph(0, 8, chip: true)]).first)
        #expect(box.minX == -3)
    }

    /// A space of 3 pt: the padding would leave no room to the word, so the box stays 2 pt from it.
    @Test func aChipKeepsTwoPointsToTheWordBeforeAndAfter() throws {
        let glyphs = [glyph(0, 8), glyph(8, 3), glyph(11, 8, chip: true), glyph(19, 3), glyph(22, 8)]
        let box = try #require(InlineCodeChipBoxes.boxes(glyphs).first)
        #expect(box.minX == 10)
        #expect(box.maxX == 20)
    }

    /// In a right-to-left line the text order runs right to left. The neighbours are found by position.
    @Test func neighboursAreFoundByPositionInARightToLeftLine() throws {
        let glyphs = [glyph(22, 8), glyph(19, 3), glyph(11, 8, chip: true), glyph(8, 3), glyph(0, 8)]
        let box = try #require(InlineCodeChipBoxes.boxes(glyphs).first)
        #expect(box.minX == 10)
        #expect(box.maxX == 20)
    }

    /// Two chips with one 4.4 pt space between them meet halfway, 2 pt apart.
    @Test func twoChipsWithOneSpaceStayTwoPointsApart() {
        let glyphs = [glyph(0, 8, chip: true), glyph(8, 4.4), glyph(12.4, 8, chip: true)]
        let boxes = InlineCodeChipBoxes.boxes(glyphs)
        #expect(boxes.count == 2)
        #expect(abs((boxes[1].minX - boxes[0].maxX) - 2) < 0.001, "gap \(boxes[1].minX - boxes[0].maxX)")
        #expect(boxes[0].maxX >= 8)
        #expect(boxes[1].minX <= 12.4)
    }

    /// Blanks at the end of a chip stay outside the box.
    @Test func trailingBlanksOfAChipAreLeftOut() throws {
        let box = try #require(InlineCodeChipBoxes.boxes([glyph(0, 8, chip: true), glyph(8, 4, chip: true, blank: true)]).first)
        #expect(box.maxX == 10)
    }
}
