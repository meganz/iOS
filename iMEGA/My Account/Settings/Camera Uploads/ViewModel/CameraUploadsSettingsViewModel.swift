import MEGAAnalyticsiOS
import MEGAAppPresentation

enum CUSettingsEvent {
    case cameraUploads(Bool)
    case videoUploads(Bool)
    case cameraUploadsFormat(CameraUploadsFormat)
    case megaUploadFolderUpdated
    case photosLocationTags(Bool)
    case cameraUploadsMobileData(Bool)
}

enum CameraUploadsFormat: Int {
    case HEIC, JPG
}

final class CameraUploadsSettingsViewModel: NSObject {
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }
    
    func trackEvent(_ event: CUSettingsEvent) {
        switch event {
        case .cameraUploads(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? CameraUploadsEnabledEvent() : CameraUploadsDisabledEvent()
            )
        case .videoUploads(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? VideoUploadsEnabledEvent() : VideoUploadsDisabledEvent()
            )
        case .cameraUploadsFormat(let format):
            switch format {
            case .HEIC:
                tracker.trackAnalyticsEvent(with: CameraUploadsFormatHEICSelectedEvent())
            case .JPG:
                tracker.trackAnalyticsEvent(with: CameraUploadsFormatJPGSelectedEvent())
            }
        case .megaUploadFolderUpdated:
            tracker.trackAnalyticsEvent(with: MegaUploadFolderUpdatedEvent())
        case .photosLocationTags(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? PhotosLocationTagsEnabledEvent() : PhotosLocationTagsDisabledEvent()
            )
        case .cameraUploadsMobileData(let enabled):
            tracker.trackAnalyticsEvent(
                with: enabled ? CameraUploadsMobileDataEnabledEvent() : CameraUploadsMobileDataDisabledEvent()
            )
        }
    }
}
