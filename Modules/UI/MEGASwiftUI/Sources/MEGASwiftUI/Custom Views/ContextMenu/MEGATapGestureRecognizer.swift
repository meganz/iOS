import UIKit.UIGestureRecognizerSubclass

/// Implement hooks to create on-touch down highlight state in the view even on the scroll view
class MEGATapGestureRecognizer: UITapGestureRecognizer {
    var began: () -> Void = {}
    var end: () -> Void = {}
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        began()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        end()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        end()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        end()
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        super.pressesEnded(presses, with: event)
        end()
    }
    
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        super.pressesCancelled(presses, with: event)
        end()
    }
    
    override func reset() {
        super.reset()
        end()
    }
}
