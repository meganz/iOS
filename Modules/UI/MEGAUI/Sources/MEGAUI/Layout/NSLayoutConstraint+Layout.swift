import UIKit

public extension Array where Element == NSLayoutConstraint {
    @MainActor
    func activate() {
        NSLayoutConstraint.activate(self)
    }
    
    @MainActor
    func deactivate() {
        NSLayoutConstraint.deactivate(self)
    }
}

public extension NSLayoutConstraint {
    func using(priority: Float) -> NSLayoutConstraint {
        self.priority = UILayoutPriority(rawValue: priority)
        return self
    }
}
