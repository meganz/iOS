import UIKit

// This extension makes it easier to create a UIAction with a simple closure.
public extension UIAction {
    /**
     Creates a UIAction with a closure that runs when the action is triggered.

     - Parameter action: A closure with no parameters that will be executed when the action is triggered.
     */
    convenience init(action: @escaping () -> Void) {
        self.init { _ in action() }
    }
}
