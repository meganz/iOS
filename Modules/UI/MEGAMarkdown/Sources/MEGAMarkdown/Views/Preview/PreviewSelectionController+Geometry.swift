import MEGADesignToken
import UIKit

// MARK: - SelectionGeometrySource

// Every preview row is selected whole, like a divider in the editor: point offset 0 is before the row, 1 after it.
extension PreviewSelectionController: SelectionGeometrySource {
    /// The start caret stands at the top leading corner of its row, the end caret at the bottom trailing corner.
    func caretRect(for point: SelectionPoint) -> CGRect? {
        guard let list, point.row < store.count else { return nil }
        let frame = blockFrame(ofItem: point.row, in: list)
        let height = min(frame.height, bodyLineHeight)
        let isEnd = point.offset > 0
        let isRightToLeft = list.view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let x = isEnd == isRightToLeft ? frame.minX : frame.maxX - 2
        return CGRect(x: x, y: isEnd ? frame.maxY - height : frame.minY, width: 2, height: height)
    }

    /// One rect per selected row on screen. An end off screen gets a zero-width rect at its stored frame,
    /// else the system draws a bare handle bar at the last rect it got.
    func selectionRects(for span: SelectionSpan) -> [UITextSelectionRect] {
        guard let list else { return [] }
        let count = store.count
        let direction: NSWritingDirection = list.view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        let visible = list.view.indexPathsForVisibleItems.map(list.item(for:)).filter { $0 < count && $0 >= span.start.row && $0 <= span.end.row }
        var result: [UITextSelectionRect] = visible.sorted().map { item in
            SelectionRect(frame: blockFrame(ofItem: item, in: list), direction: direction,
                          isStart: item == span.start.row, isEnd: item == span.end.row)
        }
        for (point, isStart) in [(span.start, true), (span.end, false)] where !result.contains(where: { isStart ? $0.containsStart : $0.containsEnd }) {
            guard let caret = caretRect(for: point) else { continue }
            let edge = CGRect(x: caret.minX, y: caret.minY, width: 0, height: caret.height)
            result.append(SelectionRect(frame: edge, direction: direction, isStart: isStart, isEnd: !isStart))
        }
        return result
    }

    /// The part of a row the block draws: without the side padding, and for the last row of a block without the gap below.
    private func blockFrame(ofItem item: Int, in list: MarkdownRowList) -> CGRect {
        var frame = list.itemFrame(at: item).insetBy(dx: TokenSpacing._5, dy: 0)
        let isLastOfBlock = item + 1 >= store.count || !store[item + 1].continuesBlock
        if isLastOfBlock {
            let estimator = gapHeights.estimator(for: list.view, theme: list.theme)
            frame.size.height = max(1, frame.height - estimator.gapHeight(store[item].chrome.gapBelow))
        }
        return frame
    }

    /// The height of a handle: one body line of the theme at the list's text size.
    private var bodyLineHeight: CGFloat {
        guard let list else { return 0 }
        return list.theme.resolved(for: list.view.traitCollection).bodyFont.lineHeight
    }
}
