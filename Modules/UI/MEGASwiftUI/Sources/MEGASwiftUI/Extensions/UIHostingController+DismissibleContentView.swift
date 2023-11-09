import SwiftUI

public protocol DismissibleContentView {
    var invokeDismiss: (() -> Void)? { get set }
}

public extension UIHostingController where Content: DismissibleContentView {
    convenience init(dismissibleView: Content) {
        self.init(rootView: dismissibleView)
        if #unavailable(iOS 15) {
            self.rootView.invokeDismiss = { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }
}
