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
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    init(
        tracker: some AnalyticsTracking = DIContainer.tracker,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
    }

    /// Whether the "Upload only new photos" row should be shown. Gated behind the feature flag so
    /// the option has no UI entry point until it is rolled out.
    @objc var shouldShowUploadOnlyNewPhotosOption: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .uploadOnlyNewPhotos)
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
