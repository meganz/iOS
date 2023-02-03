enum FilterType: String, CaseIterable {
    case none
    case allMedia
    case images
    case videos
    
    var localizedString: String {
        switch self {
        case .allMedia:
            return Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.allMedia
        case .images:
            return Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.images
        case .videos:
            return Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.videos
        case .none:
            return ""
        }
    }
}
