extension TimelineUserAttributeEntity {
    
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
}
