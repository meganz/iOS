@testable import MEGA
import MEGADomain

final class MockPhotoLibraryUseCase: PhotoLibraryUseCaseProtocol {
    private let allPhotos: [NodeEntity]
    private let allPhotosFromCloudDriveOnly: [NodeEntity]
    private let allPhotosFromCameraUpload: [NodeEntity]
    
    init(allPhotos: [NodeEntity], allPhotosFromCloudDriveOnly: [NodeEntity], allPhotosFromCameraUpload: [NodeEntity]) {
        self.allPhotos = allPhotos
        self.allPhotosFromCloudDriveOnly = allPhotosFromCloudDriveOnly
        self.allPhotosFromCameraUpload = allPhotosFromCameraUpload
    }
    
    func photoLibraryContainer() async -> PhotoLibraryContainerEntity {
        PhotoLibraryContainerEntity(cameraUploadNode: nil, mediaUploadNode: nil)
    }
    
    func cameraUploadPhotos() async throws -> [NodeEntity] {
        []
    }
    
    func allPhotos() async throws -> [NodeEntity] {
        allPhotos
    }
    
    func allPhotosFromCloudDriveOnly() async throws -> [NodeEntity] {
        allPhotosFromCloudDriveOnly
    }
    
    func allPhotosFromCameraUpload() async throws -> [NodeEntity] {
        allPhotosFromCameraUpload
    }
}
