

/// This gesture will help the user to know when the finger is lifted from the screen.
/// Please note: This gesture can be cancelled if the user of the gesture is not interested in the event temporarily.
class FingerLiftupGestureRecognizer: UIGestureRecognizer {
        
    // MARK: - Interface methods.
    
    func failGestureIfRecognized() {
        guard state == .possible else {
            return
        }
        
        state = .failed
    }
    
    // MARK: - Overriden methods.

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        if state == .possible {
            state = .ended
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        if state == .possible {
            state = .ended
        }
    }
}
