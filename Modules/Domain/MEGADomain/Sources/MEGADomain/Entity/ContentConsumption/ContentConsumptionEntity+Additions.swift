import Foundation

// MARK: SensitiveNodesUserAttributeEntity Mapper
extension ContentConsumptionEntity {
    
    func toSensitiveNodesUserAttributeEntity() -> SensitiveNodesUserAttributeEntity {
        .init(onboarded: sensitives.onboarded, showHiddenNodes: ios.sensitives.showHiddenNodes)
    }
}

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
        var mutated = self
        mutated.ios.timeline = timeline.toContentConsumptionIosTimeline()
        return mutated
    }
    
    func updateSensitive(onboarded: Bool) -> Self {
        var mutated = self
        mutated.sensitives.onboarded = onboarded
        return mutated
    }
    
    func updateSensitive(showHiddenNodes: Bool) -> Self {
        var mutated = self
        mutated.ios.sensitives.showHiddenNodes = showHiddenNodes
        return mutated
    }
}
