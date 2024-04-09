import Foundation

public struct TimelineUserAttributeEntity: Sendable, Equatable {
    public let mediaType: MediaType
    public let location: MediaLocation
    public let usePreference: Bool
    
    public enum MediaType: Sendable {
        case allMedia
        case images
        case videos
    }

    public enum MediaLocation: Sendable {
        case allLocations
        case cloudDrive
        case cameraUploads
    }
    
    public init(mediaType: MediaType, location: MediaLocation, usePreference: Bool) {
        self.mediaType = mediaType
        self.location = location
        self.usePreference = usePreference
    }
}
