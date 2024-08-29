import Foundation

public struct PhotosFilterOptionsEntity: OptionSet, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let images = PhotosFilterOptionsEntity(rawValue: 1 << 0)
    public static let videos = PhotosFilterOptionsEntity(rawValue: 1 << 1)
    public static let cloudDrive = PhotosFilterOptionsEntity(rawValue: 1 << 2)
    public static let cameraUploads = PhotosFilterOptionsEntity(rawValue: 1 << 3)
    public static let favourites = PhotosFilterOptionsEntity(rawValue: 1 << 4)
    
    public static let allMedia: PhotosFilterOptionsEntity = [.images, .videos]
    public static let allLocations: PhotosFilterOptionsEntity = [.cloudDrive, .cameraUploads]
}
