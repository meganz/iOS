import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

extension AnalyticsTracking {
    func trackFilterChange(new option: PhotosFilterOptionsEntity) {
        let event: (any EventIdentifier)? = switch option {
        case .allMedia: MediaScreenFilterAllMediaSelectedEvent()
        case .images: MediaScreenFilterImagesSelectedEvent()
        case .videos: MediaScreenFilterVideosSelectedEvent()
        case .allLocations: MediaScreenFilterAllLocationsSelectedEvent()
        case .cloudDrive: MediaScreenFilterCloudDriveSelectedEvent()
        case .cameraUploads: MediaScreenFilterCameraUploadsSelectedEvent()
        default: nil
        }
        guard let event else { return }
        trackAnalyticsEvent(with: event)
    }
}
