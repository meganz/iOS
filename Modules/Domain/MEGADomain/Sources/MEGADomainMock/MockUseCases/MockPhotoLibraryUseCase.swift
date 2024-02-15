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
    
    public func allPhotos() async throws -> [NodeEntity] {
        allPhotos
    }
    
    public func allPhotosFromCloudDriveOnly() async throws -> [NodeEntity] {
        allPhotosFromCloudDriveOnly
    }
    
    public func allPhotosFromCameraUpload() async throws -> [NodeEntity] {
        allPhotosFromCameraUpload
    }
}
