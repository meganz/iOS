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

    /// Maps the timeline filter-chip selection to the paginated-timeline query scope.
    /// The media/location parts are read independently via `mediaSelection` /
    /// `locationSelection`, so a combined set such as `[.images, .cloudDrive]` maps
    /// correctly. An empty or unrecognised selection falls back to all-media /
    /// all-locations, matching the timeline's default "show everything" behaviour.
    public func toMediaTimelineFilterEntity() -> MediaTimelineFilterEntity {
        let mediaType: MediaTimelineFilterEntity.MediaType = switch mediaSelection {
        case .images: .images
        case .videos: .videos
        default: .allMedia
        }
        let location: MediaTimelineFilterEntity.Location = switch locationSelection {
        case .cloudDrive: .cloudDrive
        case .cameraUploads: .cameraUploads
        default: .allLocations
        }
        return MediaTimelineFilterEntity(mediaType: mediaType, location: location)
    }
}
