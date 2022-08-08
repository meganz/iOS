import UIKit

public extension UIViewController {

    /// Disable given scrollView's adjusting content inset behavior.
    /// - Parameter scrollView: The scrollView whose `contentInset` would not be automatically adjusted by current view controller.
    func disableAdjustingContentInsets(for scrollView: UIScrollView) {
        scrollView.contentInsetAdjustmentBehavior = .never
    }
}
