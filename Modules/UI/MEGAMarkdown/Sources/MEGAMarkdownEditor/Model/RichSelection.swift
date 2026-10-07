import Foundation

/// A caret position in the document.
struct RichPosition: Hashable, Comparable, Sendable {
    var blockIndex: Int
    /// UTF-16 offset in the block text. See `RichBlock.length` for blocks without text.
    var offset: Int

    init(blockIndex: Int, offset: Int) {
        self.blockIndex = blockIndex
        self.offset = offset
    }

    static func < (lhs: RichPosition, rhs: RichPosition) -> Bool {
        (lhs.blockIndex, lhs.offset) < (rhs.blockIndex, rhs.offset)
    }
}

/// A caret or a selected range. It can span blocks. `start` is never after `end`.
struct RichSelection: Hashable, Sendable {
    private(set) var start: RichPosition
    private(set) var end: RichPosition

    init(start: RichPosition, end: RichPosition) {
        self.start = min(start, end)
        self.end = max(start, end)
    }

    static func caret(_ position: RichPosition) -> RichSelection {
        RichSelection(start: position, end: position)
    }

    /// A range inside one block.
    static func range(_ range: Range<Int>, inBlock blockIndex: Int) -> RichSelection {
        RichSelection(start: RichPosition(blockIndex: blockIndex, offset: range.lowerBound),
                      end: RichPosition(blockIndex: blockIndex, offset: range.upperBound))
    }

    var isCaret: Bool { start == end }

    var isInOneBlock: Bool { start.blockIndex == end.blockIndex }

    /// The selected range of `start`'s block, when the selection is inside one block.
    var rangeInBlock: Range<Int>? {
        isInOneBlock ? start.offset..<end.offset : nil
    }

    var blockIndexes: ClosedRange<Int> { start.blockIndex...end.blockIndex }

    /// The rows a block action changes. A range that ends at the start of a row selects nothing of that row.
    var touchedBlockIndexes: ClosedRange<Int> {
        let endsAtRowStart = !isCaret && end.offset == 0 && end.blockIndex > start.blockIndex
        return start.blockIndex...(endsAtRowStart ? end.blockIndex - 1 : end.blockIndex)
    }
}

extension RichBlock {
    /// `offset` moved into 0...length, and off the middle of a surrogate pair.
    func clampedOffset(_ offset: Int) -> Int {
        let clamped = max(0, min(offset, length))
        return plainText?.alignedUTF16Offset(clamped) ?? clamped
    }
}

extension RichDocument {
    /// Positions moved into the document: a valid block and an offset inside it.
    func clamped(_ position: RichPosition) -> RichPosition {
        guard !blocks.isEmpty else { return RichPosition(blockIndex: 0, offset: 0) }
        let index = max(0, min(position.blockIndex, blocks.count - 1))
        return RichPosition(blockIndex: index, offset: blocks[index].clampedOffset(position.offset))
    }

    func clamped(_ selection: RichSelection) -> RichSelection {
        RichSelection(start: clamped(selection.start), end: clamped(selection.end))
    }

    /// From the start of the first block to the end of the last block.
    var wholeSelection: RichSelection {
        guard let last = blocks.indices.last else { return .caret(RichPosition(blockIndex: 0, offset: 0)) }
        return RichSelection(start: RichPosition(blockIndex: 0, offset: 0), end: RichPosition(blockIndex: last, offset: blocks[last].length))
    }
}
