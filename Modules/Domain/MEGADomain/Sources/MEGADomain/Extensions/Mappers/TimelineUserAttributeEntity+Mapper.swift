extension TimelineUserAttributeEntity {
    
    public func toPhotoFilterOptionsEntity() -> PhotosFilterOptionsEntity {
        [mediaTypeFilterOptions, locationFilterOptions]
    }
    
    func toContentConsumptionIosTimeline() -> ContentConsumptionIosTimeline {
        .init(
            mediaType: toContentConsumptionIosTimelineMediaType,
            location: contentConsumptionIosTimelineMediaLocation,
            usePreference: usePreference)
    }
    
    private var toContentConsumptionIosTimelineMediaType: ContentConsumptionIosTimeline.MediaType {
        switch mediaType {
        case .allMedia: return .allMedia
        case .images: return .images
        case .videos: return .videos
        }
    }
    
    private var contentConsumptionIosTimelineMediaLocation: ContentConsumptionIosTimeline.MediaLocation {
        switch location {
        case .allLocations: return .allLocations
        case .cloudDrive: return .cloudDrive
        case .cameraUploads: return .cameraUploads
        }
    }
    
    private var mediaTypeFilterOptions: PhotosFilterOptionsEntity {
        switch mediaType {
        case .allMedia: .allMedia
        case .images: .images
        case .videos: .videos
        }
    }
    
    private var locationFilterOptions: PhotosFilterOptionsEntity {
        switch location {
        case .allLocations: .allLocations
        case .cloudDrive: .cloudDrive
        case .cameraUploads: .cameraUploads
        }
    }
}
