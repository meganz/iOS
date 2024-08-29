import Foundation

public protocol PublicAlbumUseCaseProtocol: Sendable {
    func publicAlbum(forLink link: String) async throws -> SharedCollectionEntity
    func publicPhotos(_ photos: [SetElementEntity]) async -> [NodeEntity]
    func stopAlbumLinkPreview()
}

public struct PublicAlbumUseCase<S: ShareCollectionRepositoryProtocol>: PublicAlbumUseCaseProtocol {
    private let shareCollectionRepository: S
    
    public init(shareCollectionRepository: S) {
        self.shareCollectionRepository = shareCollectionRepository
    }
    
    public func publicAlbum(forLink link: String) async throws -> SharedCollectionEntity {
        try await shareCollectionRepository.publicCollectionContents(forLink: link)
    }
    
    public func publicPhotos(_ photos: [SetElementEntity]) async -> [NodeEntity] {
        return await withTaskGroup(of: NodeEntity?.self) { group in
            photos.forEach { photoElement in
                group.addTask {
                    try? await shareCollectionRepository.publicNode(photoElement)
                }
            }
            return await group.reduce(into: [NodeEntity]()) {
                if let photo = $1 { $0.append(photo) }
            }
        }
    }
    
    public func stopAlbumLinkPreview() {
        shareCollectionRepository.stopCollectionLinkPreview()
    }
}
