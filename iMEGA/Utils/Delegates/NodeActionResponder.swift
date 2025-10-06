import MEGAAnalyticsiOS
import MEGAAppPresentation

struct NodeActionResponder {
    private let tracker: any AnalyticsTracking
    private let selectedNodesHandler: ([MEGANode]) -> Void

    init(tracker: some AnalyticsTracking = DIContainer.tracker, selectedNodesHandler: @escaping ([MEGANode]) -> Void) {
        self.tracker = tracker
        self.selectedNodesHandler = selectedNodesHandler
    }
    
    func nodeActionListener() -> (MegaNodeActionType?, [MEGANode]) -> Void {
        { action, selectedNodes in
            switch action {
            case .hide:
                tracker.trackAnalyticsEvent(with: HideNodeMenuItemEvent())
            case .select:
                selectedNodesHandler(selectedNodes)
            default:
                {}()
            }
        }
    }
}
