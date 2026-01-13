extension PhotosFilterOptionsEntity {
    public func toTimelineUserAttributeMediaTypeEntity() -> TimelineUserAttributeEntity.MediaType? {
        switch self {
        case .allMedia: .allMedia
        case .images: .images
        case .videos: .videos
        default: nil
        }
    }
    
    public func toTimelineUserAttributeMediaLocationEntity() -> TimelineUserAttributeEntity.MediaLocation? {
        switch self {
        case .allLocations: .allLocations
        case .cloudDrive: .cloudDrive
        case .cameraUploads: .cameraUploads
        default: nil
        }
    }
}
