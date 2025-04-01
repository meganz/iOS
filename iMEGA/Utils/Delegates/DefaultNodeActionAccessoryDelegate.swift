import MEGAAnalyticsiOS
import MEGAAppPresentation

@objc final class DefaultNodeAccessoryActionDelegate: NSObject, NodeAccessoryActionDelegate {
    nonisolated override init() {
        super.init()
    }
    
    func nodeAccessoryAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType) {
        switch action {
        case .hide:
            DIContainer.tracker.trackAnalyticsEvent(with: HideNodeInfoButtonPressedEvent())
            
            HideFilesAndFoldersRouter(presenter: nodeAction)
                .showOnboardingInfo()
        default: break
        }
    }
}
