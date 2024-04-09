import Foundation

// MARK: TimelineUserAttributeEntity Mapper
extension ContentConsumptionEntity {
    
    func toTimelineUserAttributeEntity() -> TimelineUserAttributeEntity {
        .init(
            mediaType: toTimelineUserAttributeEntityMediaType,
            location: toTimelineUserAttributeEntityMediaLocation,
            usePreference: ios.timeline.usePreference)
    }
    
    private var toTimelineUserAttributeEntityMediaType: TimelineUserAttributeEntity.MediaType {
        switch ios.timeline.mediaType {
        case .allMedia: .allMedia
        case .images: .images
        case .videos: .videos
        }
    }
    
    private var toTimelineUserAttributeEntityMediaLocation: TimelineUserAttributeEntity.MediaLocation {
        switch ios.timeline.location {
        case .allLocations: .allLocations
        case .cameraUploads: .cameraUploads
        case .cloudDrive: .cloudDrive
        }
    }
}

// MARK: Update Model
extension ContentConsumptionEntity {
    
    func update(timeline: TimelineUserAttributeEntity) -> Self {
        ContentConsumptionEntity(
            ios: ContentConsumptionIos(
                timeline: timeline.toContentConsumptionIosTimeline())
        )
    }
}
