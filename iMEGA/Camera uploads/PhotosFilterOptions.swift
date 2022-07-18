import Foundation

struct PhotosFilterOptions: OptionSet {
    static let allMedia = PhotosFilterOptions(rawValue: 1)
    static let images = PhotosFilterOptions(rawValue: 1 << 1)
    static let videos = PhotosFilterOptions(rawValue: 1 << 2)
    
    static let allLocations = PhotosFilterOptions(rawValue: 1 << 3)
    static let cloudDrive = PhotosFilterOptions(rawValue: 1 << 4)
    static let cameraUploads = PhotosFilterOptions(rawValue: 1 << 5)
    
    let rawValue: Int8
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
