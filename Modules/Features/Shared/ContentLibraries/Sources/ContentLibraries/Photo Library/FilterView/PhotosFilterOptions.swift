import Foundation
import MEGADomain
import MEGAL10n

public enum PhotosFilterType: CaseIterable, Sendable {
    case allMedia
    case images
    case videos
    
    public var localization: String {
        var type = ""
        switch self {
        case .allMedia: type = Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.allMedia
        case .images: type = Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.images
        case .videos: type = Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.videos
        }
        return type
    }
}

public extension PhotosFilterType {
    func toContentConsumptionMediaType() -> TimelineUserAttributeEntity.MediaType {
        switch self {
        case .allMedia: return .allMedia
        case .images: return .images
        case .videos: return .videos
        }
    }
    
    func toPhotosFilterOptions() -> PhotosFilterOptions {
        switch self {
        case .images: .images
        case .videos: .videos
        default: .allMedia
        }
    }
    
    static func toFilterType(from contentConsumptionMediaType: TimelineUserAttributeEntity.MediaType) -> PhotosFilterType {
        switch contentConsumptionMediaType {
        case .allMedia: return .allMedia
        case .images: return .images
        case .videos: return .videos
        }
    }
}

public enum PhotosFilterLocation: CaseIterable, Sendable {
    case allLocations
    case cloudDrive
    case cameraUploads
    
    public var localization: String {
        var location = ""
        switch self {
        case .allLocations: location = Strings.Localizable.CameraUploads.Timeline.Filter.Location.allLocations
        case .cloudDrive: location = Strings.Localizable.CameraUploads.Timeline.Filter.Location.cloudDrive
        case .cameraUploads: location = Strings.Localizable.CameraUploads.Timeline.Filter.Location.cameraUploads
        }
        return location
    }
}

public extension PhotosFilterLocation {
    func toContentConsumptionMediaLocation() -> TimelineUserAttributeEntity.MediaLocation {
        switch self {
        case .allLocations: return .allLocations
        case .cloudDrive: return .cloudDrive
        case .cameraUploads: return .cameraUploads
        }
    }
    
    func toPhotosFilterOptions() -> PhotosFilterOptions {
        switch self {
        case .cloudDrive: .cloudDrive
        case .cameraUploads: .cameraUploads
        default: .allLocations
        }
    }
    
    static func toFilterLocation(from contentConsumptionMediaLocation: TimelineUserAttributeEntity.MediaLocation) -> PhotosFilterLocation {
        switch contentConsumptionMediaLocation {
        case .allLocations: return .allLocations
        case .cloudDrive: return .cloudDrive
        case .cameraUploads: return .cameraUploads
        }
    }
}

public struct PhotosFilterOptions: OptionSet, Sendable {
    public static let allMedia = PhotosFilterOptions(rawValue: 1)
    public static let images = PhotosFilterOptions(rawValue: 1 << 1)
    public static let videos = PhotosFilterOptions(rawValue: 1 << 2)
    
    public static let allLocations = PhotosFilterOptions(rawValue: 1 << 3)
    public static let cloudDrive = PhotosFilterOptions(rawValue: 1 << 4)
    public static let cameraUploads = PhotosFilterOptions(rawValue: 1 << 5)
    
    public let rawValue: Int8
    
    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }
}

extension PhotosFilterOptions {
    static var allImages: PhotosFilterOptions {
        return [.images, .allLocations]
    }
    
    static var allVideos: PhotosFilterOptions {
        return [.videos, .allLocations]
    }
    
    static var allVisualFiles: PhotosFilterOptions {
        return [.allMedia, .allLocations]
    }
    
    static var cloudDriveImages: PhotosFilterOptions {
        return [.images, .cloudDrive]
    }
    
    static var cloudDriveVideos: PhotosFilterOptions {
        return [.videos, .cloudDrive]
    }
    
    static var cloudDriveAll: PhotosFilterOptions {
        return [.allMedia, .cloudDrive]
    }
    
    static var cameraUploadImages: PhotosFilterOptions {
        return [.images, .cameraUploads]
    }
    
    static var cameraUploadVideos: PhotosFilterOptions {
        return [.videos, .cameraUploads]
    }
    
    static var cameraUploadAll: PhotosFilterOptions {
        return [.allMedia, .cameraUploads]
    }
}

public extension PhotosFilterOptions {
    func toPhotosFilterOptionsEntity() -> PhotosFilterOptionsEntity {
        var entity: PhotosFilterOptionsEntity = []
        
        if isSuperset(of: .allMedia) {
            entity.insert(.allMedia)
        }
        
        if contains(.images) {
            entity.insert(.images)
        }
        
        if contains(.videos) {
            entity.insert(.videos)
        }
        
        if isSuperset(of: .allLocations) {
            entity.insert(.allLocations)
        }
        
        if contains(.cloudDrive) {
            entity.insert(.cloudDrive)
        }
        
        if contains(.cameraUploads) {
            entity.insert(.cameraUploads)
        }
        
        return entity
    }
}
