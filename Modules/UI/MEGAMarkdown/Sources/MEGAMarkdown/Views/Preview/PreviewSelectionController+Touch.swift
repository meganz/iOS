import UIKit

// The touch path. The list watcher calls the touch methods, the long press recognizer the long press ones.
// Points are in the list view.
extension PreviewSelectionController {
    // MARK: - Long press

    @objc func longPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let listView else { return }
        let point = gesture.location(in: listView)
        switch gesture.state {
        case .began:
            longPressBegan(at: point)
        case .changed:
            longPressMoved(to: point, inWindow: gesture.location(in: nil))
        case .ended, .cancelled, .failed:
            longPressEnded()
        default:
            break
        }
    }

    /// Selects the block under the finger. Moving on grows the selection block by block.
    func longPressBegan(at point: CGPoint) {
        // A finger that holds still on a handle keeps the handle drag.
        if let drag, drag.grabsStart != nil { return }
        guard let row = row(at: point) else { return }
        if case .notice = store[row].content { return }
        onBegin?()
        selection = PreviewSelection(anchorRow: row, headRow: row)
        drag = (nil, .zero, true)
        // A move after the long press grows the selection. It must not also scroll the list.
        if let pan = listView?.panGestureRecognizer { SelectionDragWatcher.cancel([pan]) }
        dismissEditMenu()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func longPressMoved(to point: CGPoint, inWindow: CGPoint) {
        guard let drag, drag.grabsStart == nil, drag.isDragging else { return }
        moveHead(to: point, inWindow: inWindow, offset: .zero)
    }

    func longPressEnded() {
        guard let drag, drag.grabsStart == nil, drag.isDragging else { return }
        finishDrag()
    }

    // MARK: - Handles and taps

    /// A touch on a handle or inside the highlight stops the rows' own taps (links). The list pan and the long press stay.
    func touchBegan(at point: CGPoint, others: [UIGestureRecognizer]) {
        touchStart = (point, CACurrentMediaTime())
        isTouchOnSelection = false
        if let drag, drag.grabsStart == nil, drag.isDragging { return }
        drag = nil
        guard let span = displayInput.span else { return }
        if let grab = SelectionGeometry.handleGrab(at: point, startCaret: caretRect(for: span.start), endCaret: caretRect(for: span.end)) {
            drag = (grab.grabsStart, grab.offset, false)
        }
        isTouchOnSelection = drag != nil || selectionRects(for: span).contains { $0.rect.width > 0 && $0.rect.contains(point) }
        if isTouchOnSelection, let pan = listView?.panGestureRecognizer {
            SelectionDragWatcher.cancel(others.filter { $0 !== pan && $0 !== longPress })
        }
    }

    /// Returns true when the layer owns the touch: a handle drag.
    func touchMoved(to point: CGPoint, inWindow: CGPoint, others: [UIGestureRecognizer]) -> Bool {
        guard let current = drag, let grabsStart = current.grabsStart, let listView else { return false }
        if !current.isDragging {
            guard let rows = selectedRows else { return false }
            // The list pan has not begun yet at the first move, so it is stopped by name.
            SelectionDragWatcher.cancel(others + [listView.panGestureRecognizer])
            selection = grabsStart
                ? PreviewSelection(anchorRow: rows.upperBound, headRow: rows.lowerBound)
                : PreviewSelection(anchorRow: rows.lowerBound, headRow: rows.upperBound)
            drag = (grabsStart, current.offset, true)
            onBegin?()
            dismissEditMenu()
            loupe = UITextLoupeSession.begin(at: point, fromSelectionWidgetView: nil, in: listView)
        }
        moveHead(to: point, inWindow: inWindow, offset: current.offset)
        return true
    }

    /// A tap on the selection shows the edit menu again. A tap elsewhere clears it. A scroll keeps it.
    /// A touch the system cancels is never a tap, and a handle drag still ends normally.
    func touchEnded(at point: CGPoint, listPanBegan: Bool, cancelled: Bool) {
        defer {
            touchStart = nil
            isTouchOnSelection = false
        }
        if let current = drag {
            // A long press drag ends in its own recognizer.
            guard current.grabsStart != nil else { return }
            if current.isDragging {
                finishDrag()
                return
            }
            drag = nil
        }
        guard !cancelled, selection != nil, let start = touchStart,
              SelectionGeometry.isTap(from: start.point, to: point, duration: CACurrentMediaTime() - start.time,
                                      listPanBegan: listPanBegan) else { return }
        if isTouchOnSelection {
            presentEditMenu()
        } else {
            clear()
        }
    }

    /// The list scrolled under a finger that holds still: the head follows the content.
    func autoscrolled() {
        guard let drag, drag.isDragging, let listView, let finger = lastFingerInWindow else { return }
        let point = listView.convert(finger, from: nil)
        updateHead(at: CGPoint(x: point.x + drag.offset.x, y: point.y + drag.offset.y))
        loupe?.move(to: point, withCaretRect: .null, trackingCaret: false)
    }

    // MARK: - Steps

    private func moveHead(to point: CGPoint, inWindow: CGPoint, offset: CGPoint) {
        lastFingerInWindow = inWindow
        updateHead(at: CGPoint(x: point.x + offset.x, y: point.y + offset.y))
        loupe?.move(to: point, withCaretRect: .null, trackingCaret: false)
        autoScroller?.update(fingerInWindow: inWindow)
    }

    private func updateHead(at point: CGPoint) {
        guard let current = selection, let row = row(at: point), row != current.headRow else { return }
        selection = PreviewSelection(anchorRow: current.anchorRow, headRow: row)
    }

    private func finishDrag() {
        autoScroller?.stop()
        loupe?.invalidate()
        loupe = nil
        drag = nil
        lastFingerInWindow = nil
        presentEditMenu()
    }

    /// The row under a point. Above the first row: the first; below the last: the last.
    func row(at point: CGPoint) -> Int? {
        guard let list, store.count > 0 else { return nil }
        if let item = list.item(at: point), item < store.count { return item }
        return point.y < 0 ? 0 : store.count - 1
    }

}

// MARK: - UIGestureRecognizerDelegate

extension PreviewSelectionController: UIGestureRecognizerDelegate {
    /// The long press never blocks the list pan, links or the sideways scroll of code and tables.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
