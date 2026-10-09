import Foundation

/// Rules of the selection drag that need no view. Points and frames are in the list view.
package enum SelectionGeometry {
    /// A drag takes over from the native selection when the finger is this far outside its row.
    package static let takeoverMargin: CGFloat = 8
    /// Height of the edge zone that scrolls the list while a selection drag holds there.
    package static let autoscrollZone: CGFloat = 54
    /// Speed at the outer edge of the zone, in points per second.
    package static let autoscrollMaxSpeed: CGFloat = 1_500
    /// A touch that moves less than this is a tap.
    package static let tapSlop: CGFloat = 10
    /// A touch held this long is a long press, not a tap. Same as `UILongPressGestureRecognizer`.
    package static let longPressDuration: TimeInterval = 0.5
    /// The edit menu keeps this far from the selection above and below, so it does not cover the handle knobs.
    package static let menuMargin: CGFloat = 24

    /// True for a touch that clears a selection over rows. A scroll or a long press keeps it.
    package static func isTap(from start: CGPoint, to end: CGPoint, duration: TimeInterval, listPanBegan: Bool) -> Bool {
        !listPanBegan && duration < longPressDuration && hypot(end.x - start.x, end.y - start.y) <= tapSlop
    }

    /// The touch area of a selection handle: 44 pt wide around the caret bar, reaching further up for the start handle
    /// (its knob is on top) and further down for the end handle (its knob is below).
    package static func handleZone(caret: CGRect, isStart: Bool) -> CGRect {
        caret.insetBy(dx: -22, dy: -14).offsetBy(dx: 0, dy: isStart ? -6 : 6)
    }

    /// The handle a touch at `point` grabs, and the offset from the finger to that handle's caret.
    /// The end wins: at a short selection the zones overlap, and growing the end is the common move.
    package static func handleGrab(at point: CGPoint, startCaret: CGRect?, endCaret: CGRect?) -> (grabsStart: Bool, offset: CGPoint)? {
        if let endCaret, handleZone(caret: endCaret, isStart: false).contains(point) {
            return (false, CGPoint(x: endCaret.midX - point.x, y: endCaret.midY - point.y))
        }
        if let startCaret, handleZone(caret: startCaret, isStart: true).contains(point) {
            return (true, CGPoint(x: startCaret.midX - point.x, y: startCaret.midY - point.y))
        }
        return nil
    }

    /// The union of the parts of `rects` inside `visible`, or nil when no part is inside.
    /// The edit menu points at this, so it points at the part of the selection the user sees.
    package static func visibleBounds(of rects: [CGRect], in visible: CGRect) -> CGRect? {
        let parts = rects.map { $0.intersection(visible) }.filter { !$0.isNull }
        guard let first = parts.first else { return nil }
        return parts.dropFirst().reduce(first) { $0.union($1) }
    }

    /// True when `point` left the row frame by more than the margin, above or below.
    package static func leftRow(_ point: CGPoint, rowFrame: CGRect) -> Bool {
        point.y < rowFrame.minY - takeoverMargin || point.y > rowFrame.maxY + takeoverMargin
    }

    /// True when the touch started nearer the end caret than the start caret. At equal distance the end wins.
    /// A text view does not update `selectedRange` while its handle moves, so the touch start decides.
    package static func grabsEnd(touch: CGPoint, startCaret: CGRect, endCaret: CGRect) -> Bool {
        distance(touch, startCaret) >= distance(touch, endCaret)
    }

    /// Scroll speed for a finger at `y`, between the visible top and bottom of the list.
    /// Negative scrolls up. Zero outside the edge zones.
    package static func autoscrollSpeed(fingerY y: CGFloat, visibleTop top: CGFloat, visibleBottom bottom: CGFloat) -> CGFloat {
        let zone = min(autoscrollZone, max(0, (bottom - top) / 2))
        guard zone > 0 else { return 0 }
        if y < top + zone {
            return -autoscrollMaxSpeed * min(1, (top + zone - y) / zone)
        }
        if y > bottom - zone {
            return autoscrollMaxSpeed * min(1, (y - (bottom - zone)) / zone)
        }
        return 0
    }

    /// The offset for a finger at `y` with no text view: the start above the middle, the end below.
    /// For a block without text `length` is 1, and `frame` spans all its items, so a split block has one middle.
    package static func offset(y: CGFloat, frame: CGRect, length: Int) -> Int {
        y < frame.midY ? 0 : length
    }

    private static func distance(_ point: CGPoint, _ rect: CGRect) -> CGFloat {
        hypot(rect.midX - point.x, rect.midY - point.y)
    }
}
