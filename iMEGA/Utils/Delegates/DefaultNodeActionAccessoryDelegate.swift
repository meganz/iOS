import Foundation

@objc final class DefaultNodeAccessoryActionDelegate: NSObject, NodeAccessoryActionDelegate {
    func nodeAccessoryAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType) {
        switch action {
        case .hide:
            HideFilesAndFoldersRouter(presenter: nodeAction)
                .showOnboardingInfo()
        default: break
        }
    }
    
    nonisolated override init() {
        super.init()
    }
}
