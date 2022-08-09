import Foundation

/// A protocol that must be adopted by `NSObject` instances to handle error from a source of UIViewController.
protocol ErrorHandling: NSObject {

    /// Handle an error which is from `UIViewControllers` with a retry completion.
    /// Usually errors should be handled separately in the `UIViewController` who populates them.
    /// - Parameters:
    ///   - error: The `Error` to be handled.
    ///   - viewController: The view controller instance where the error is originated.
    ///   - retryHandler: An optional handler function that will be triggered with a retry.
    func handle(_ error: Error, from viewController: UIViewController, retryHandler: (() -> Void)?)
}
