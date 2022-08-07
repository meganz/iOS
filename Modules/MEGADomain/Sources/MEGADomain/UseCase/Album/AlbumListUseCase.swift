import Foundation

public protocol AlbumListUseCaseProtocol {
    func loadCameraUploadNode() async throws -> NodeEntity?
}

public struct AlbumListUseCase<T: AlbumRepositoryProtocol>: AlbumListUseCaseProtocol {
    private let albumRepository: T
    
    public init(repository: T) {
        albumRepository = repository
    }
    
    public func loadCameraUploadNode() async throws -> NodeEntity? {
        return try await albumRepository.loadCameraUploadNode()
    }
}
