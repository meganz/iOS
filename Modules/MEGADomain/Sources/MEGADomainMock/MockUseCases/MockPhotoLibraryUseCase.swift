import MEGADomain

public struct MockPhotoLibraryUseCase: PhotoLibraryUseCaseProtocol {
    private let allPhotos: [NodeEntity]
    private let allPhotosFromCloudDriveOnly: [NodeEntity]
    private let allPhotosFromCameraUpload: [NodeEntity]
    
    public init(allPhotos: [NodeEntity] = [],
         allPhotosFromCloudDriveOnly: [NodeEntity] = [],
         allPhotosFromCameraUpload: [NodeEntity] = []) {
        self.allPhotos = allPhotos
        self.allPhotosFromCloudDriveOnly = allPhotosFromCloudDriveOnly
        self.allPhotosFromCameraUpload = allPhotosFromCameraUpload
    }
    
    public func photoLibraryContainer() async -> PhotoLibraryContainerEntity {
        PhotoLibraryContainerEntity(cameraUploadNode: nil, mediaUploadNode: nil)
    }
    
    public func cameraUploadPhotos() async throws -> [NodeEntity] {
        []
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
