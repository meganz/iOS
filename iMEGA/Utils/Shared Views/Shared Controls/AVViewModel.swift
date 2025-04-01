import MEGAAnalyticsiOS
import MEGAAppPresentation

@objc final class AVViewModel: NSObject {
    private let videoPlayerScreenEvent = VideoPlayerScreenEvent()
    
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    @objc func onViewDidLoad() {
        tracker.trackAnalyticsEvent(with: videoPlayerScreenEvent)
    }
}
