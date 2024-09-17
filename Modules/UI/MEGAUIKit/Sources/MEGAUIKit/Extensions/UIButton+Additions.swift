import UIKit

// This extension adds a convenience initializer to UIButton to create a button with a specified action.
public extension UIButton {
    /**
     Creates a UIButton and assigns a closure to be executed when the button is tapped.

     - Parameter action: A closure that will be called when the button is tapped.
     */
    convenience init(action: @escaping () -> Void) {
        self.init()
        addAction(UIAction(action: action), for: .touchUpInside)
    }
}
