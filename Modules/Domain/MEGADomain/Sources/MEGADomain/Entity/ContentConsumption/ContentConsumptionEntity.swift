import Foundation

public enum ContentConsumptionMediaType: String, Codable, Sendable {
    case allMedia
    case images
    case videos
}

public enum ContentConsumptionMediaLocation: String, Codable, Sendable {
    case allLocations
    case cloudDrive
    case cameraUploads
}

public struct ContentConsumptionTimeline: Codable, Sendable {
    public let mediaType: ContentConsumptionMediaType
    public let location: ContentConsumptionMediaLocation
    public let usePreference: Bool?
    
    public init(
        mediaType: ContentConsumptionMediaType,
        location: ContentConsumptionMediaLocation,
        usePreference: Bool?
    ) {
        self.mediaType = mediaType
        self.location = location
        self.usePreference = usePreference
    }
}

public struct ContentConsumptionIos: Codable, Sendable {
    public let timeline: ContentConsumptionTimeline
    
    public init(timeline: ContentConsumptionTimeline) {
        self.timeline = timeline
    }
}

public struct ContentConsumptionEntity: Codable, Sendable {
    public let ios: ContentConsumptionIos
    
    public init(ios: ContentConsumptionIos) {
        self.ios = ios
    }
    
    public func update(timeline: ContentConsumptionTimeline) -> ContentConsumptionEntity {
        ContentConsumptionEntity(ios: ContentConsumptionIos(timeline: timeline))
    }
}
