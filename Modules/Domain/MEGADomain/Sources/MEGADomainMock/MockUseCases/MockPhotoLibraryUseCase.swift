import MEGADomain

public struct MockPhotoLibraryUseCase: PhotoLibraryUseCaseProtocol {

    private let allPhotos: [NodeEntity]
    private let allPhotosFromCloudDriveOnly: [NodeEntity]
    private let allPhotosFromCameraUpload: [NodeEntity]
    private let photoLibraryContainer: PhotoLibraryContainerEntity
    
    public init(
        allPhotos: [NodeEntity] = [],
        allPhotosFromCloudDriveOnly: [NodeEntity] = [],
        allPhotosFromCameraUpload: [NodeEntity] = [],
        photoLibraryContainer: PhotoLibraryContainerEntity = PhotoLibraryContainerEntity(cameraUploadNode: nil, mediaUploadNode: nil)
    ) {
        self.allPhotos = allPhotos
        self.allPhotosFromCloudDriveOnly = allPhotosFromCloudDriveOnly
        self.allPhotosFromCameraUpload = allPhotosFromCameraUpload
        self.photoLibraryContainer = photoLibraryContainer
    }
    
    public func photoLibraryContainer() async -> PhotoLibraryContainerEntity {
        photoLibraryContainer
    }
    
    public func media(for filterOptions: PhotosFilterOptionsEntity, excludeSensitive: Bool?) async throws -> [NodeEntity] {
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
            allPhotos
        } else if filterOptions.contains(.cloudDrive) {
            allPhotosFromCloudDriveOnly
        } else if filterOptions.contains(.cameraUploads) {
            allPhotosFromCameraUpload
        } else {
            []
        }
    }
}
