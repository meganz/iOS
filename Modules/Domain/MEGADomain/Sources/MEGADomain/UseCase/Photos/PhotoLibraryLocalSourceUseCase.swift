import Foundation

public struct PhotoLibraryLocalSourceUseCase<T: PhotoLibraryRepositoryProtocol, U: PhotosRepositoryProtocol>: PhotoLibraryUseCaseProtocol {

    private let photoLibraryRepository: T
    private let photosRepository: U
    
    public init(photoLibraryRepository: T,
                photosRepository: U) {
        self.photoLibraryRepository = photoLibraryRepository
        self.photosRepository = photosRepository
    }
    
    public func photoLibraryContainer() async -> PhotoLibraryContainerEntity {
        async let cameraUploadNode = try? await photoLibraryRepository.photoSourceNode(for: .camera)
        async let mediaUploadNode = try? await photoLibraryRepository.photoSourceNode(for: .media)
        
        return await PhotoLibraryContainerEntity(
            cameraUploadNode: cameraUploadNode,
            mediaUploadNode: mediaUploadNode
        )
    }
    
    public func media(for filterOptions: PhotosFilterOptionsEntity, excludeSensitive: Bool?, searchText: String, sortOrder: SortOrderEntity) async throws -> [NodeEntity] {
        []
    }
    
    public func allPhotos() async throws -> [NodeEntity] {
        try await photosRepository.allPhotos()
    }
    
    public func allPhotosFromCloudDriveOnly() async throws -> [NodeEntity] {
        let container = await photoLibraryContainer()
        return try await allPhotos()
            .filter { [container.cameraUploadNode?.handle,
                       container.mediaUploadNode?.handle].notContains($0.parentHandle) }
    }
    
    public func allPhotosFromCameraUpload() async throws -> [NodeEntity] {
        let container = await photoLibraryContainer()
        let cameraUploadHandles = [container.cameraUploadNode,
                                   container.mediaUploadNode].compactMap { $0?.handle }
        guard cameraUploadHandles.isNotEmpty else {
            return []
        }
        return try await allPhotos()
            .filter { cameraUploadHandles.contains($0.parentHandle) }
    }
}
