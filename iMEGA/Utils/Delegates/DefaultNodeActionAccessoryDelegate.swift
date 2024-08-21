import Foundation

@objc final class DefaultNodeActionAccessoryDelegate: NSObject, NodeActionAccessoryViewControllerDelegate {
    func nodeAccessoryAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType) {
        switch action {
        case .hide:
            // CC-7939: Show onboarding info
            nodeAction.dismiss(animated: true, completion: nil)
        default: break
        }
    }
}
