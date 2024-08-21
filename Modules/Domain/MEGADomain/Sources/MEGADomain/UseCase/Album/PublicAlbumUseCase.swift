import Foundation

public protocol PublicAlbumUseCaseProtocol {
    func publicAlbum(forLink link: String) async throws -> SharedCollectionEntity
    func publicPhotos(_ photos: [SetElementEntity]) async -> [NodeEntity]
    func stopAlbumLinkPreview()
}

public struct PublicAlbumUseCase<S: ShareAlbumRepositoryProtocol>: PublicAlbumUseCaseProtocol {
    private let shareAlbumRepository: S
    
    public init(shareAlbumRepository: S) {
        self.shareAlbumRepository = shareAlbumRepository
    }
    
    public func publicAlbum(forLink link: String) async throws -> SharedCollectionEntity {
        try await shareAlbumRepository.publicAlbumContents(forLink: link)
    }
    
    public func publicPhotos(_ photos: [SetElementEntity]) async -> [NodeEntity] {
        return await withTaskGroup(of: NodeEntity?.self) { group in
            photos.forEach { photoElement in
                group.addTask {
                    try? await shareAlbumRepository.publicPhoto(photoElement)
                }
            }
            return await group.reduce(into: [NodeEntity]()) {
                if let photo = $1 { $0.append(photo) }
            }
        }
    }
    
    public func stopAlbumLinkPreview() {
        shareAlbumRepository.stopAlbumLinkPreview()
    }
}
