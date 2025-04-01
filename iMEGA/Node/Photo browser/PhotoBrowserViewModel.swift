import MEGAAnalyticsiOS
import MEGAAppPresentation

@objc final class PhotoBrowserViewModel: NSObject {
    
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    @objc func onViewDidLoad() {
        tracker.trackAnalyticsEvent(with: DIContainer.photoPreviewScreenEvent)
    }
    
    @objc func trackAnalyticsSaveToDeviceMenuToolbarEvent() {
        tracker.trackAnalyticsEvent(
            with: DIContainer.photoPreviewSaveToDeviceMenuToolbarEvent)
    }
    
    @objc func trackHideNodeMenuEvent() {
        tracker.trackAnalyticsEvent(with: ImagePreviewHideNodeMenuToolBarEvent())
    }
}
