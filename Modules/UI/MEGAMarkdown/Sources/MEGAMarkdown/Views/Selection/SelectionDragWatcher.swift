import UIKit

/// Watches every touch on the list without taking it. It recognizes only when the selection layer takes a drag over,
/// so the list pan, the text views and the checkboxes keep working.
@MainActor
package final class SelectionDragWatcher: UIGestureRecognizer, UIGestureRecognizerDelegate {
    /// A touch started at a point in the list view. `others` are the touch's other recognizers.
    package var onBegan: ((_ point: CGPoint, _ others: [UIGestureRecognizer]) -> Void)?
    /// The touch moved. `others` are the touch's other recognizers that have begun. Returns true to take the touch over.
    package var onMoved: ((_ point: CGPoint, _ inWindow: CGPoint, _ others: [UIGestureRecognizer]) -> Bool)?
    /// The touch ended. `listPanBegan` is true when the list scrolled during the touch.
    /// `cancelled` is true when the system cancelled it, for example for an incoming call.
    package var onEnded: ((_ point: CGPoint, _ listPanBegan: Bool, _ cancelled: Bool) -> Void)?

    private var tracked: UITouch?
    private var listPanBegan = false

    override package init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    // It never blocks another recognizer, and none blocks it.
    override package func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override package func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    package func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                   shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    override package func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        // A second finger is not a selection drag.
        guard tracked == nil, touches.count == 1, let touch = touches.first else {
            if !isTakenOver { state = .failed }
            return
        }
        tracked = touch
        listPanBegan = false
        onBegan?(touch.location(in: view), (touch.gestureRecognizers ?? []).filter { $0 !== self })
    }

    override package func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let tracked, touches.contains(tracked) else { return }
        let others = (tracked.gestureRecognizers ?? []).filter { $0 !== self && ($0.state == .began || $0.state == .changed) }
        if others.contains(where: { $0 === (view as? UIScrollView)?.panGestureRecognizer }) { listPanBegan = true }
        let wants = onMoved?(tracked.location(in: view), tracked.location(in: nil), others) ?? false
        if isTakenOver {
            state = .changed
        } else if wants {
            state = .began
        }
    }

    override package func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        finish(touches, cancelled: false)
    }

    override package func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        finish(touches, cancelled: true)
    }

    override package func reset() {
        super.reset()
        tracked = nil
        listPanBegan = false
    }

    /// Cancels recognizers by turning them off and on. They get no more of the current touch.
    package static func cancel(_ recognizers: [UIGestureRecognizer]) {
        for recognizer in recognizers {
            recognizer.isEnabled = false
            recognizer.isEnabled = true
        }
    }

    private var isTakenOver: Bool {
        state == .began || state == .changed
    }

    private func finish(_ touches: Set<UITouch>, cancelled: Bool) {
        guard let tracked, touches.contains(tracked) else { return }
        onEnded?(tracked.location(in: view), listPanBegan, cancelled)
        if isTakenOver {
            state = cancelled ? .cancelled : .ended
        } else {
            state = .failed
        }
    }
}
