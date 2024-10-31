import UIKit

public extension UIView {
    /// Retrieves the first constraint from the view that matches the given identifier.
    ///
    /// This method searches the view's constraints for a constraint whose `identifier`
    /// property matches the provided `identifier` string. If a matching constraint is found,
    /// it is returned; otherwise, the method returns `nil`.
    ///
    /// - Parameter identifier: The identifier of the constraint to search for.
    /// - Returns: An optional `NSLayoutConstraint` that matches the given identifier, or `nil` if no match is found.
    func constraint(with identifier: String) -> NSLayoutConstraint? {
        constraints.first { $0.identifier == identifier }
    }
}
