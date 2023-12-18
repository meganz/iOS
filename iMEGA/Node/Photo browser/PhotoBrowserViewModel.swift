import MEGAAnalyticsiOS
import MEGAPresentation

@objc final class PhotoBrowserViewModel: NSObject {
    private let photoPreviewScreenEvent = PhotoPreviewScreenEvent()
    private lazy var photoPreviewSaveToDeviceMenuToolbarEvent = PhotoPreviewSaveToDeviceMenuToolbarEvent()
    
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    @objc func onViewDidLoad() {
        tracker.trackAnalyticsEvent(with: photoPreviewScreenEvent)
    }
    
    @objc func trackAnalyticsSaveToDeviceMenuToolbarEvent() {
        tracker.trackAnalyticsEvent(
            with: photoPreviewSaveToDeviceMenuToolbarEvent)
    }
}
