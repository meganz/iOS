import Combine
import MEGADomain

public actor MockPhotoLibraryUseCase: PhotoLibraryUseCaseProtocol {

    private let allPhotos: [NodeEntity]
    private let allPhotosFromCloudDriveOnly: [NodeEntity]
    private let allPhotosFromCameraUpload: [NodeEntity]
    private let allVideos: [NodeEntity]
    private let photoLibraryContainer: PhotoLibraryContainerEntity
    
    private var succesfullyLoadMedia = true
    
    @Published public private(set) var messages = [Message]()
    
    public enum Message: Sendable {
        case media
    }
    
    public init(
        allPhotos: [NodeEntity] = [],
        allPhotosFromCloudDriveOnly: [NodeEntity] = [],
        allPhotosFromCameraUpload: [NodeEntity] = [],
        allVideos: [NodeEntity] = [],
        photoLibraryContainer: PhotoLibraryContainerEntity = PhotoLibraryContainerEntity(cameraUploadNode: nil, mediaUploadNode: nil),
        succesfullyLoadMedia: Bool = true
    ) {
        self.allPhotos = allPhotos
        self.allPhotosFromCloudDriveOnly = allPhotosFromCloudDriveOnly
        self.allPhotosFromCameraUpload = allPhotosFromCameraUpload
        self.allVideos = allVideos
        self.photoLibraryContainer = photoLibraryContainer
        self.succesfullyLoadMedia = succesfullyLoadMedia
    }
    
    public func photoLibraryContainer() async -> PhotoLibraryContainerEntity {
        photoLibraryContainer
    }
    
    public func media(for filterOptions: PhotosFilterOptionsEntity, excludeSensitive: Bool?, searchText: String, sortOrder: SortOrderEntity) async throws -> [NodeEntity] {
        
        guard succesfullyLoadMedia else {
            throw GenericErrorEntity()
        }
        
        messages.append(.media)
        let media = mediaForLocation(filterOptions)
        
        return if filterOptions.isSuperset(of: .allMedia) {
            media
        } else if filterOptions.contains(.images) {
            media.filter { $0.name.fileExtensionGroup.isImage }
        } else if filterOptions.contains(.videos) {
            media.filter { $0.name.fileExtensionGroup.isVideo }
        } else {
            []
        }
    }
    
    private func mediaForLocation(_ filterOptions: PhotosFilterOptionsEntity) -> [NodeEntity] {
        return if filterOptions.isSuperset(of: .allLocations) {
            allPhotos + allVideos
        } else if filterOptions.contains(.cloudDrive) {
            allPhotosFromCloudDriveOnly
        } else if filterOptions.contains(.cameraUploads) {
            allPhotosFromCameraUpload
        } else {
            []
        }
    }
}
