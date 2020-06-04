import UIKit

extension UIViewController {

    /// Disable given scrollView's adjusting content inset behavior.
    /// - Parameter scrollView: The scrollView whose `contentInset` would not be automatically adjusted by current view controller.
    func disableAdjustingContentInsets(ofScrollView scrollView: UIScrollView) {
        if #available(iOS 11, *) {
            // Recommended method introduced from iOS 11
            scrollView.contentInsetAdjustmentBehavior = .never
        } else if #available(iOS 7, *) {
            // Deprecated setting compatible from iOS 7 - iOS 11
            automaticallyAdjustsScrollViewInsets = false
        }
    }
}
