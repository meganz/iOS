@testable import MEGA

final class MockPhotoLibraryUseCase: PhotoLibraryUseCaseProtocol {
    private let allPhotos: [MEGANode]
    private let allPhotosFromCloudDriveOnly: [MEGANode]
    private let allPhotosFromCameraUpload: [MEGANode]
    
    init(allPhotos: [MEGANode], allPhotosFromCloudDriveOnly: [MEGANode], allPhotosFromCameraUpload: [MEGANode]) {
        self.allPhotos = allPhotos
        self.allPhotosFromCloudDriveOnly = allPhotosFromCloudDriveOnly
        self.allPhotosFromCameraUpload = allPhotosFromCameraUpload
    }
    
    func photoLibraryContainer() async -> PhotoLibraryContainerEntity {
        PhotoLibraryContainerEntity(cameraUploadNode: nil, mediaUploadNode: nil)
    }
    
    func cameraUploadPhotos() async throws -> [MEGANode] {
        []
    }
    
    func allPhotos() async throws -> [MEGANode] {
        allPhotos
    }
    
    func allPhotosFromCloudDriveOnly() async throws -> [MEGANode] {
        allPhotosFromCloudDriveOnly
    }
    
    func allPhotosFromCameraUpload() async throws -> [MEGANode] {
        allPhotosFromCameraUpload
    }
}
