import UIKit

public extension UIView {
    /// Checks if the current view or any of its subviews is the first responder.
    ///
    /// A first responder is an object that is currently receiving input events. This
    /// method recursively checks if the current view or any of its subviews is the
    /// first responder by examining their `isFirstResponder` property.
    ///
    /// - Returns: `true` if the current view or any of its subviews is the first responder;
    ///            otherwise, `false`.
    ///
    /// Example usage:
    /// ```swift
    /// let view = UIView()
    /// let textField = UITextField()
    /// view.addSubview(textField)
    ///
    /// textField.becomeFirstResponder()
    ///
    /// if view.containsFirstResponder() {
    ///     print("The view or one of its subviews is the first responder.")
    /// } else {
    ///     print("No subviews are the first responder.")
    /// }
    /// ```
    func containsFirstResponder() -> Bool {
        if isFirstResponder {
            return true
        }

        for subview in subviews where subview.containsFirstResponder() {
            return true
        }

        return false
    }
}
