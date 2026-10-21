import MEGAMarkdown
import UIKit

// MARK: - SelectionGeometrySource

extension CrossBlockSelectionController: SelectionGeometrySource {
    func caretRect(for point: SelectionPoint) -> CGRect? {
        caretRect(for: RichPosition(blockIndex: point.row, offset: point.offset))
    }

    func selectionRects(for span: SelectionSpan) -> [UITextSelectionRect] {
        selectionRects(for: RichSelection(
            start: RichPosition(blockIndex: span.start.row, offset: span.start.offset),
            end: RichPosition(blockIndex: span.end.row, offset: span.end.offset)
        ))
    }

    func caretRect(for position: RichPosition) -> CGRect? {
        guard let adapter, adapter.appliedVersion == adapter.model.version, position.blockIndex < adapter.model.rowCount else {
            return nil
        }
        let items = adapter.items(forRow: position.blockIndex)
        guard adapter.model.row(at: position.blockIndex).block.plainText != nil else {
            return atomicCaret(items: items, after: position.offset > 0)
        }
        guard let textView = adapter.textView(forItem: items.lowerBound),
              let caret = textView.position(from: textView.beginningOfDocument, offset: position.offset) else { return nil }
        return textView.convert(textView.caretRect(for: caret), to: adapter.list.view)
    }

    func selectionRects(for selection: RichSelection) -> [UITextSelectionRect] {
        guard let adapter, adapter.appliedVersion == adapter.model.version else { return [] }
        let itemCount = adapter.list.itemCount
        let visible = adapter.list.view.indexPathsForVisibleItems.map(adapter.list.item(for:)).filter { $0 < itemCount }.sorted()
        var result: [UITextSelectionRect] = []
        for item in visible {
            let row = adapter.row(forItem: item).row
            guard selection.blockIndexes.contains(row), row < adapter.model.rowCount else { continue }
            let block = adapter.model.row(at: row).block
            let from = row == selection.start.blockIndex ? selection.start.offset : 0
            let to = row == selection.end.blockIndex ? selection.end.offset : block.length
            if block.plainText == nil {
                result += atomicRects(item: item, row: row, from: from, to: to, selection: selection)
            } else {
                result += textRects(item: item, row: row, from: from, to: to, selection: selection)
            }
        }
        // An end off screen still needs a rect, else the system draws a bare handle bar at the last rect it got.
        if !result.contains(where: \.containsStart) {
            result.append(offscreenEdge(selection.start, isStart: true))
        }
        if !result.contains(where: \.containsEnd) {
            result.append(offscreenEdge(selection.end, isStart: false))
        }
        return result
    }

    /// A zero-width rect at the stored frame of an edge's row with no cell: top leading for the start, bottom
    /// trailing for the end. A block without text gets its caret before or after it, from that item's frame.
    private func offscreenEdge(_ position: RichPosition, isStart: Bool) -> UITextSelectionRect {
        if let adapter, position.blockIndex < adapter.model.rowCount, adapter.model.row(at: position.blockIndex).block.plainText == nil,
           let caret = atomicCaret(items: adapter.items(forRow: position.blockIndex), after: position.offset > 0) {
            return SelectionRect(frame: caret, direction: layoutDirection, isStart: isStart, isEnd: !isStart)
        }
        let frame = adapter.map { adapter in
            let items = adapter.items(forRow: position.blockIndex)
            return adapter.list.itemFrame(at: isStart ? items.lowerBound : items.upperBound - 1)
        } ?? .zero
        let content = frame.insetBy(dx: rowInset, dy: 0)
        let height = min(frame.height, bodyLineHeight)
        let isRightToLeft = layoutDirection == .rightToLeft
        let x = isStart == isRightToLeft ? content.maxX : content.minX
        let rect = CGRect(x: x, y: isStart ? frame.minY : frame.maxY - height, width: 0, height: height)
        return SelectionRect(frame: rect, direction: layoutDirection, isStart: isStart, isEnd: !isStart)
    }

    private func textRects(item: Int, row: Int, from: Int, to: Int, selection: RichSelection) -> [UITextSelectionRect] {
        guard let adapter, let textView = adapter.textView(forItem: item),
              let start = textView.position(from: textView.beginningOfDocument, offset: from),
              let end = textView.position(from: textView.beginningOfDocument, offset: max(from, to)),
              let range = textView.textRange(from: start, to: end) else { return [] }
        let listView = adapter.list.view
        let isStartRow = row == selection.start.blockIndex
        let isEndRow = row == selection.end.blockIndex
        guard from < to else {
            // Nothing of this row is selected, but a handle stands at its caret.
            guard isStartRow || isEndRow else { return [] }
            let caret = textView.convert(textView.caretRect(for: start), to: listView)
            return [SelectionRect(frame: caret, direction: direction(of: textView), isStart: isStartRow, isEnd: isEndRow)]
        }
        let rowDirection = direction(of: textView)
        return textView.selectionRects(for: range).compactMap { rect in
            let isStart = isStartRow && rect.containsStart
            let isEnd = isEndRow && rect.containsEnd
            guard rect.rect.width > 0 || isStart || isEnd else { return nil }
            return SelectionRect(frame: textView.convert(rect.rect, to: listView), direction: rowDirection,
                                 isStart: isStart, isEnd: isEnd)
        }
    }

    private func atomicRects(item: Int, row: Int, from: Int, to: Int, selection: RichSelection) -> [UITextSelectionRect] {
        guard let adapter else { return [] }
        let items = adapter.items(forRow: row)
        // An edge before the block (offset 0) stands on its first item, an edge after it on its last item.
        let isStart = row == selection.start.blockIndex && item == edgeItem(items, offset: selection.start.offset)
        let isEnd = row == selection.end.blockIndex && item == edgeItem(items, offset: selection.end.offset)
        guard from < to else {
            // The row is outside the selection. Only its caret before or after it can carry a handle.
            guard isStart || isEnd, let caret = atomicCaret(items: items, after: from > 0) else { return [] }
            return [SelectionRect(frame: caret, direction: layoutDirection, isStart: isStart, isEnd: isEnd)]
        }
        return [SelectionRect(frame: atomicFrame(item: item, row: row), direction: layoutDirection, isStart: isStart, isEnd: isEnd)]
    }

    /// The block part of an atomic row's item: without the side padding, and without the gap below the block,
    /// which only the row's last item has.
    private func atomicFrame(item: Int, row: Int) -> CGRect {
        guard let adapter else { return .zero }
        var frame = adapter.list.itemFrame(at: item).insetBy(dx: rowInset, dy: 0)
        if item == adapter.items(forRow: row).upperBound - 1 {
            let estimator = gapHeights.estimator(for: adapter.list.view, theme: adapter.theme)
            frame.size.height = max(1, frame.height - estimator.gapHeight(adapter.chrome[row].gapBelow))
        }
        return frame
    }

    /// A caret of a block without text: at its top leading corner (before it) or its bottom trailing corner (after it).
    /// UIKit draws a handle on a whole selected block at those corners, so the handle is grabbed where it shows.
    private func atomicCaret(items: Range<Int>, after: Bool) -> CGRect? {
        guard let adapter, !items.isEmpty else { return nil }
        let item = edgeItem(items, offset: after ? 1 : 0)
        let frame = atomicFrame(item: item, row: adapter.row(forItem: item).row)
        let height = min(frame.height, bodyLineHeight)
        let isTrailing = after != (layoutDirection == .rightToLeft)
        let x = isTrailing ? frame.maxX - 2 : frame.minX
        return CGRect(x: x, y: after ? frame.maxY - height : frame.minY, width: 2, height: height)
    }

    /// The item of a block without text that holds its caret: the first item before the block, the last item after it.
    private func edgeItem(_ items: Range<Int>, offset: Int) -> Int {
        offset > 0 ? items.upperBound - 1 : items.lowerBound
    }

    /// The height of a handle on a row without a text view: one body line of the list's theme and text size.
    private var bodyLineHeight: CGFloat {
        guard let adapter else { return 0 }
        return adapter.theme.resolved(for: adapter.list.view.traitCollection).bodyFont.lineHeight
    }

    private var rowInset: CGFloat { RichRowAdapter.rowSideInset }

    private var layoutDirection: NSWritingDirection {
        adapter?.list.view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }

    /// A text view reports left to right in its selection rects even for a right-to-left paragraph, so the first two
    /// carets decide. TextKit picks the direction from the first strong letter: "iOS שלום" runs left to right.
    private func direction(of textView: UITextView) -> NSWritingDirection {
        guard let second = textView.position(from: textView.beginningOfDocument, offset: 1) else { return layoutDirection }
        let first = textView.caretRect(for: textView.beginningOfDocument).midX
        return textView.caretRect(for: second).midX < first ? .rightToLeft : .leftToRight
    }
}

// MARK: - Point to position

extension CrossBlockSelectionController {
    /// The caret position under a point in the list view.
    func position(at point: CGPoint) -> RichPosition {
        guard let adapter else { return RichPosition(blockIndex: 0, offset: 0) }
        let model = adapter.model
        guard let item = adapter.list.item(at: point) else {
            guard point.y >= 0, model.rowCount > 0 else { return RichPosition(blockIndex: 0, offset: 0) }
            let last = model.rowCount - 1
            return RichPosition(blockIndex: last, offset: model.row(at: last).block.length)
        }
        let row = adapter.row(forItem: item).row
        let block = model.row(at: row).block
        guard block.plainText != nil else {
            let items = adapter.items(forRow: row)
            let frame = adapter.list.itemFrame(at: items.lowerBound).union(adapter.list.itemFrame(at: items.upperBound - 1))
            return RichPosition(blockIndex: row, offset: SelectionGeometry.offset(y: point.y, frame: frame, length: 1))
        }
        guard let textView = adapter.textView(forItem: item),
              let closest = textView.closestPosition(to: textView.convert(point, from: adapter.list.view)) else {
            let offset = SelectionGeometry.offset(y: point.y, frame: adapter.list.itemFrame(at: item), length: block.length)
            return RichPosition(blockIndex: row, offset: offset)
        }
        let offset = textView.offset(from: textView.beginningOfDocument, to: closest)
        return RichPosition(blockIndex: row, offset: block.clampedOffset(offset))
    }
}
