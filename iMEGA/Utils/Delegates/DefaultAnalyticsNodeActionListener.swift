import MEGAAnalyticsiOS
import MEGAPresentation

struct DefaultAnalyticsNodeActionListener {
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    func nodeActionListener() -> (MegaNodeActionType?) -> Void {
        { action in
            switch action {
            case .hide:
                tracker.trackAnalyticsEvent(with: HideNodeMenuItemEvent())
            default:
                {}()
            }
        }
    }
}
