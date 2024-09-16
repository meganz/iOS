import MEGADomain

protocol AlbumContentPhotoLibraryDataProviderProtocol: Sendable {
    func updatePhotos(_ newPhotos: [AlbumPhotoEntity]) async
    func isEmpty() async -> Bool
    func isFilterEnabled(for filter: FilterType) async -> Bool
    func containsImageAndVideo() async -> Bool
    func photos(for filter: FilterType) async -> [NodeEntity]
    func nodesToAddToAlbum(_ photoNodes: [NodeEntity]) async -> [NodeEntity]
    func albumPhotosToDelete(from photoNodes: [NodeEntity]) async -> [AlbumPhotoEntity]
}

actor AlbumContentPhotoLibraryDataProvider: AlbumContentPhotoLibraryDataProviderProtocol {
    private var photos = [AlbumPhotoEntity]()
    
    func updatePhotos(_ newPhotos: [AlbumPhotoEntity]) {
        photos = newPhotos
    }
    
    func isEmpty() -> Bool {
        photos.isEmpty
    }
    
    func isFilterEnabled(for filter: FilterType) -> Bool {
        switch filter {
        case .images:
            photos.contains(where: \.photo.name.fileExtensionGroup.isImage)
        case .videos:
            photos.contains(where: \.photo.name.fileExtensionGroup.isVideo)
        default:
            containsImageAndVideo()
        }
    }
    
    func photos(for filter: FilterType) async -> [NodeEntity] {
        let filteredPhotos = switch filter {
        case .images:
            photos.filter(\.photo.name.fileExtensionGroup.isImage)
        case .videos:
            photos.filter(\.photo.name.fileExtensionGroup.isVideo)
        default:
            photos
        }
        return filteredPhotos.map(\.photo)
    }
    
    func containsImageAndVideo() -> Bool {
        var containsImage = false
        var containsVideo = false
        for albumPhoto in photos {
            if albumPhoto.photo.name.fileExtensionGroup.isImage {
                containsImage = true
            } else if albumPhoto.photo.name.fileExtensionGroup.isVideo {
                containsVideo = true
            }
            if containsImage && containsVideo {
                return true
            }
        }
        return false
    }
    
    func nodesToAddToAlbum(_ photoNodes: [NodeEntity]) -> [NodeEntity] {
        photoNodes.filter { photo in photos.notContains(where: { photo == $0.photo }) }
    }
    
    func albumPhotosToDelete(from photoNodes: [NodeEntity]) -> [AlbumPhotoEntity] {
        photos.filter { albumPhoto in photoNodes.contains(where: { albumPhoto.id == $0.handle }) }
    }
}
