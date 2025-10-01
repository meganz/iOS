import MEGAAnalyticsiOS
import MEGAAppPresentation

struct DefaultAnalyticsNodeActionListener {
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    func nodeActionListener() -> (MegaNodeActionType?, [MEGANode]) -> Void {
        { action, _ in
            switch action {
            case .hide:
                tracker.trackAnalyticsEvent(with: HideNodeMenuItemEvent())
            default:
                {}()
            }
        }
    }
}
