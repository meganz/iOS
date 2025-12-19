import MEGADomain
import MEGAL10n

extension PhotosFilterOptionsEntity {
    var identifier: String {
        switch self {
        case .images: "photosFilterOptionImage"
        case .videos: "photosFilterOptionVideos"
        case .allMedia: "photosFilterOptionImage"
        case .cloudDrive: "photosFilterOptionCloudDrive"
        case .cameraUploads: "photosFilterOptionCameraUploads"
        case .allLocations: "photosFilterOptionAllLocations"
        default: "photosFilterOption"
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .images: Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.images
        case .videos: Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.videos
        case .allMedia: Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.allMedia
        case .cloudDrive: Strings.Localizable.CameraUploads.Timeline.Filter.Location.cloudDrive
        case .cameraUploads: Strings.Localizable.CameraUploads.Timeline.Filter.Location.cameraUploads
        case .allLocations: Strings.Localizable.CameraUploads.Timeline.Filter.Location.allLocations
        default: ""
        }
    }
}
