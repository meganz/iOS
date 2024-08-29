import Foundation

@objc final class DefaultNodeAccessoryActionDelegate: NSObject, NodeAccessoryActionDelegate {
    @MainActor
    func nodeAccessoryAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType) {
        switch action {
        case .hide, .unhide:
            HideFilesAndFoldersRouter(presenter: nodeAction)
                .showOnboardingInfo()
        default: break
        }
    }
}
