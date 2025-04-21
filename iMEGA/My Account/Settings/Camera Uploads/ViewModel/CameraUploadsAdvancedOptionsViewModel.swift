import MEGAAnalyticsiOS
import MEGAAppPresentation

enum CameraUploadsAdvancedOptionsEvent {
    case livePhotoVideoUploads(Bool)
    case burstPhotosUpload(Bool)
    case hiddenAlbumUpload(Bool)
    case sharedAlbumsUpload(Bool)
    case iTunesSyncedAlbumsUpload(Bool)
}

final class CameraUploadsAdvancedOptionsViewModel: NSObject {
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    func trackEvent(_ event: CameraUploadsAdvancedOptionsEvent) {
        switch event {
        case .livePhotoVideoUploads(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? LivePhotoVideoUploadsEnabledEvent() : LivePhotoVideoUploadsDisabledEvent()
            )
        case .burstPhotosUpload(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? BurstPhotosUploadEnabledEvent() : BurstPhotosUploadDisabledEvent()
            )
        case .hiddenAlbumUpload(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? HiddenAlbumUploadEnabledEvent() : HiddenAlbumUploadDisabledEvent()
            )
        case .sharedAlbumsUpload(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? SharedAlbumsUploadEnabledEvent() : SharedAlbumsUploadDisabledEvent()
            )
        case .iTunesSyncedAlbumsUpload(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? ITunesSyncedAlbumsUploadEnabledEvent() : ITunesSyncedAlbumsUploadDisabledEvent()
            )
        }
    }
}
