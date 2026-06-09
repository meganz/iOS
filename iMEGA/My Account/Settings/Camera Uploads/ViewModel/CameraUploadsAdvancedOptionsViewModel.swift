import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

enum CameraUploadsAdvancedOptionsEvent {
    case livePhotoVideoUploads(Bool)
    case burstPhotosUpload(Bool)
    case hiddenAlbumUpload(Bool)
    case sharedAlbumsUpload(Bool)
    case iTunesSyncedAlbumsUpload(Bool)
}

final class CameraUploadsAdvancedOptionsViewModel: NSObject {
    private let tracker: any AnalyticsTracking
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol

    init(
        tracker: some AnalyticsTracking = DIContainer.tracker,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) {
        self.tracker = tracker
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }

    /// Whether the "Upload only new photos" row should be shown. Gated behind the same remote flag
    /// that gates the behaviour, so the option has no UI entry point until it is rolled out.
    @objc var shouldShowUploadOnlyNewPhotosOption: Bool {
        remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosUploadOnlyNewPhotos)
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
