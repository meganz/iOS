import Foundation
import MEGAMarkdown

/// A selection that the user drags across rows. Unlike `RichSelection`, it keeps the direction:
/// `anchor` stays still and `head` follows the finger or the arrow keys.
struct CrossBlockSelection: Equatable {
    var anchor: RichPosition
    var head: RichPosition

    var range: RichSelection {
        RichSelection(start: anchor, end: head)
    }

    /// The same range with `head` on the end the user grabbed. The other end becomes the anchor.
    func grabbing(start grabsStart: Bool) -> CrossBlockSelection {
        let range = range
        return grabsStart
            ? CrossBlockSelection(anchor: range.end, head: range.start)
            : CrossBlockSelection(anchor: range.start, head: range.end)
    }

    /// ⇧ with an arrow at a row edge: the head goes to the far edge of the next row while the selection grows,
    /// and to the near edge while it shrinks. nil at the first or last row.
    func movingHead(down: Bool, rowCount: Int, length: (Int) -> Int) -> CrossBlockSelection? {
        let target = head.blockIndex + (down ? 1 : -1)
        guard target >= 0, target < rowCount else { return nil }
        let growsDown = target > anchor.blockIndex
        let growsUp = target < anchor.blockIndex
        let offset: Int = if down {
            growsDown ? length(target) : 0
        } else {
            growsUp ? 0 : length(target)
        }
        return CrossBlockSelection(anchor: anchor, head: RichPosition(blockIndex: target, offset: offset))
    }
}

extension RichSelection {
    /// The same range for the shared selection display, which counts rows, not blocks.
    var span: SelectionSpan {
        SelectionSpan(
            SelectionPoint(row: start.blockIndex, offset: start.offset),
            SelectionPoint(row: end.blockIndex, offset: end.offset)
        )
    }
}
