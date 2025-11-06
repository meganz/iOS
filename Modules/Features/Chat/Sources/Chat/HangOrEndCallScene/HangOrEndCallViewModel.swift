import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

public enum HangOrEndCallAction {
    case leaveCall
    case endCallForAll
}

@MainActor
struct HangOrEndCallViewModel {
    private let router: any HangOrEndCallRouting
    private let tracker: any AnalyticsTracking
    
    init(
        router: some HangOrEndCallRouting,
        tracker: some AnalyticsTracking
    ) {
        self.router = router
        self.tracker = tracker
    }
    
    func leaveCall() {
        router.leaveCall()
    }
    
    func endCallForAll() {
        router.endCallForAll()
        tracker.trackAnalyticsEvent(with: EndCallForAllEvent())
    }
}
