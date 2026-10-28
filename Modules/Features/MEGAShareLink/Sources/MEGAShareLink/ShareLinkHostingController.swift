import SwiftUI
import UIKit

public final class ShareLinkHostingController<Content: View>: UIHostingController<Content>,
    UIAdaptivePresentationControllerDelegate {
    public override init(rootView: Content) {
        super.init(rootView: rootView)
        modalPresentationStyle = .formSheet
        // Without the delegate, `.formSheet` shows as a card in compact
        // width. UIKit asks it again on every size class change.
        presentationController?.delegate = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    public func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        let isRegularSize = traitCollection.horizontalSizeClass == .regular
            && traitCollection.verticalSizeClass == .regular
        return isRegularSize ? .none : .fullScreen
    }
}
