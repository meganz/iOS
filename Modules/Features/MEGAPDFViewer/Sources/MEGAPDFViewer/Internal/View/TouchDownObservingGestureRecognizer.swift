import UIKit
import UIKit.UIGestureRecognizerSubclass

/// Reports each touch-down in its view and never recognizes, so every other
/// gesture recognizer and control still receives the touch.
final class TouchDownObservingGestureRecognizer: UIGestureRecognizer {
    var onTouchDown: ((UITouch) -> Void)?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        touches.forEach { onTouchDown?($0) }
        state = .failed
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }

    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}
