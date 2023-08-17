import SwiftUI

@available(iOS, deprecated: 15.0, message: "Use EnvironmentValues.dismiss that is available in iOS 15.")
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
