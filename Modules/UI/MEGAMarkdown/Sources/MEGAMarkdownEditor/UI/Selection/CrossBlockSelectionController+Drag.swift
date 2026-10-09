import MEGAMarkdown
import UIKit

/// What a touch on the list does to the selection.
enum SelectionDrag: Equatable {
    case idle
    /// The touch started on a native handle of a range in one text row. The layer takes over when the finger leaves the row.
    case native(item: Int, row: Int, range: NSRange, grabsEnd: Bool)
    /// The touch started on a handle of the selection over rows. The layer takes over at the first move.
    case handle(grabsStart: Bool, offset: CGPoint)
    /// The layer moves the head with the finger. `offset` goes from the finger to the grabbed caret.
    case dragging(offset: CGPoint)
}

// The touch path: the watcher calls these with points in the list view.
extension CrossBlockSelectionController {
    /// A touch on a handle or inside the highlight stops the rows' own recognizers in `others`, so a tap there
    /// shows the edit menu. The list pan stays, so a scroll from there still works.
    func touchBegan(at point: CGPoint, others: [UIGestureRecognizer]) {
        touchStart = (point, CACurrentMediaTime())
        touchVersion = adapter?.model.version
        drag = .idle
        isTouchOnSelection = false
        if let range = selection?.range {
            if let grab = handleGrab(at: point, range: range) {
                drag = grab
            }
            isTouchOnSelection = drag != .idle || selectionRects(for: range).contains { $0.rect.contains(point) }
            if isTouchOnSelection, let pan = adapter?.list.view.panGestureRecognizer {
                SelectionDragWatcher.cancel(others.filter { $0 !== pan })
            }
            if drag != .idle { return }
        }
        drag = nativeHandleGrab(at: point) ?? .idle
    }

    /// Returns true when the layer owns the touch from now on.
    /// `others` are the touch's other recognizers that have begun: a takeover cancels them.
    func touchMoved(to point: CGPoint, inWindow: CGPoint, others: [UIGestureRecognizer]) -> Bool {
        switch drag {
        case .idle:
            return false
        case .native(let item, let row, let range, let grabsEnd):
            guard let adapter, SelectionGeometry.leftRow(point, rowFrame: adapter.list.itemFrame(at: item)) else { return false }
            SelectionDragWatcher.cancel(others)
            let anchorOffset = grabsEnd ? range.location : range.location + range.length
            if let textView = adapter.textView(forItem: item) {
                for case let menu as UIEditMenuInteraction in textView.interactions { menu.dismissMenu() }
                // The layer draws the selection, so the native range goes. The model does not hear of it.
                textView.setSelectionFromModel(NSRange(location: anchorOffset, length: 0))
            }
            selection = CrossBlockSelection(anchor: RichPosition(blockIndex: row, offset: anchorOffset), head: position(at: point))
            beginDrag(at: point, offset: .zero)
            moveHead(to: point, inWindow: inWindow, offset: .zero)
            return true
        case .handle(let grabsStart, let offset):
            guard let current = selection, let adapter else { return false }
            // The list pan has not begun yet at the first move, so it is stopped by name.
            SelectionDragWatcher.cancel(others + [adapter.list.view.panGestureRecognizer])
            selection = current.grabbing(start: grabsStart)
            beginDrag(at: point, offset: offset)
            moveHead(to: point, inWindow: inWindow, offset: offset)
            return true
        case .dragging(let offset):
            moveHead(to: point, inWindow: inWindow, offset: offset)
            return true
        }
    }

    /// The touch ended, or the system cancelled it. A drag hands its selection to the model in both cases.
    /// A tap on the selection shows the edit menu. A tap elsewhere places a caret. A cancelled touch is never a tap.
    func touchEnded(at point: CGPoint, listPanBegan: Bool, cancelled: Bool) {
        defer {
            drag = .idle
            touchStart = nil
            isTouchOnSelection = false
        }
        guard case .dragging = drag else {
            if !cancelled { tapped(at: point, listPanBegan: listPanBegan) }
            return
        }
        endDrag()
        guard let model = adapter?.model, let range = selection?.range else { return }
        model.setFocused(true)
        model.select(range)
        if !range.isInOneBlock { presentEditMenu() }
    }

    /// The list scrolled under a finger that holds still: the head follows the content.
    func autoscrolled() {
        guard case .dragging(let offset) = drag, let adapter, let touch = lastFingerInWindow else { return }
        let point = adapter.list.view.convert(touch, from: nil)
        updateHead(at: CGPoint(x: point.x + offset.x, y: point.y + offset.y))
        loupe?.move(to: point, withCaretRect: .null, trackingCaret: false)
    }

    /// Stops the drag without a change to the model: the autoscroll, the loupe and the finger go.
    func endDrag() {
        autoScroller?.stop()
        loupe?.invalidate()
        loupe = nil
        lastFingerInWindow = nil
        drag = .idle
    }

    // MARK: - Steps

    private func beginDrag(at point: CGPoint, offset: CGPoint) {
        guard let adapter else { return }
        drag = .dragging(offset: offset)
        dismissEditMenu()
        loupe = UITextLoupeSession.begin(at: point, fromSelectionWidgetView: nil, in: adapter.list.view)
        UISelectionFeedbackGenerator().selectionChanged()
        refreshDisplay()
    }

    private func moveHead(to point: CGPoint, inWindow: CGPoint, offset: CGPoint) {
        lastFingerInWindow = inWindow
        updateHead(at: CGPoint(x: point.x + offset.x, y: point.y + offset.y))
        loupe?.move(to: point, withCaretRect: .null, trackingCaret: false)
        autoScroller?.update(fingerInWindow: inWindow)
    }

    private func updateHead(at point: CGPoint) {
        guard let current = selection else { return }
        let head = position(at: point)
        guard head != current.head else { return }
        selection = CrossBlockSelection(anchor: current.anchor, head: head)
        refreshDisplay()
    }

    /// A tap on the selection shows the edit menu. Elsewhere the row's own tap usually moves the caret.
    /// When it did not (a gap or a margin), the caret goes to the tapped place.
    private func tapped(at point: CGPoint, listPanBegan: Bool) {
        guard let range = selection?.range, let start = touchStart,
              SelectionGeometry.isTap(from: start.point, to: point, duration: CACurrentMediaTime() - start.time,
                                      listPanBegan: listPanBegan) else { return }
        guard !isTouchOnSelection else {
            presentEditMenu()
            return
        }
        let caret = position(at: point)
        // UIKit does not say whether this runs before or after the row's own tap action. So wait one turn, and
        // act only when the row did not move the selection itself.
        Task { @MainActor [weak self] in
            guard let self, let model = adapter?.model, model.selection == range else { return }
            model.setFocused(true)
            model.select(.caret(caret))
        }
    }

    /// The item of the text row that holds the model's selection, when it is a range inside that row.
    private func nativeRangeItem(of adapter: RichRowAdapter) -> Int? {
        let selection = adapter.model.selection
        guard selection.isInOneBlock, !selection.isCaret, selection.start.blockIndex < adapter.model.rowCount else { return nil }
        return adapter.items(forRow: selection.start.blockIndex).lowerBound
    }

    /// A touch on a handle of a native range in one text row. Only such a touch can take over.
    /// A swipe from elsewhere in the row is a scroll.
    private func nativeHandleGrab(at point: CGPoint) -> SelectionDrag? {
        // The model names the row of a range with native handles. The start knob sits above the caret,
        // so the touch can be over the row above.
        guard let adapter, let item = nativeRangeItem(of: adapter),
              let textView = adapter.textView(forItem: item), textView.isFirstResponder,
              textView.selectedRange.length > 0, let range = textView.selectedTextRange else { return nil }
        let listView = adapter.list.view
        let startCaret = textView.convert(textView.caretRect(for: range.start), to: listView)
        let endCaret = textView.convert(textView.caretRect(for: range.end), to: listView)
        let onEnd = SelectionGeometry.handleZone(caret: endCaret, isStart: false).contains(point)
        let onStart = SelectionGeometry.handleZone(caret: startCaret, isStart: true).contains(point)
        guard onEnd || onStart else { return nil }
        return .native(
            item: item,
            row: adapter.row(forItem: item).row,
            range: textView.selectedRange,
            grabsEnd: onEnd && onStart ? SelectionGeometry.grabsEnd(touch: point, startCaret: startCaret, endCaret: endCaret) : onEnd
        )
    }

    /// A touch in the zone of one of the selection's handles.
    private func handleGrab(at point: CGPoint, range: RichSelection) -> SelectionDrag? {
        SelectionGeometry.handleGrab(at: point, startCaret: caretRect(for: range.start), endCaret: caretRect(for: range.end))
            .map { .handle(grabsStart: $0.grabsStart, offset: $0.offset) }
    }
}
