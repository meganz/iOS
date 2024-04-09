import Foundation
import MEGASwift

public struct ContentConsumptionIosTimeline: Codable, Sendable, Equatable {
    public let mediaType: MediaType
    public let location: MediaLocation
    public let usePreference: Bool
    
    public enum MediaType: String, Codable, Sendable {
        case allMedia
        case images
        case videos
    }

    public enum MediaLocation: String, Codable, Sendable {
        case allLocations
        case cloudDrive
        case cameraUploads
    }
    
    static let `default`: Self = .init(mediaType: .allMedia, location: .allLocations, usePreference: false)
    
    enum CodingKeys: String, CodingKey {
        case mediaType, location, usePreference
    }
    
    public init(mediaType: MediaType, location: MediaLocation, usePreference: Bool) {
        self.mediaType = mediaType
        self.location = location
        self.usePreference = usePreference
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaultValues = Self.default
        self.mediaType = try container.decodeIfPresent(for: .mediaType) ?? defaultValues.mediaType
        self.location = try container.decodeIfPresent(for: .location) ?? defaultValues.location
        self.usePreference = try container.decodeIfPresent(for: .usePreference) ?? defaultValues.usePreference
    }
}
