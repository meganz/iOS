import Foundation

public protocol PublicAlbumUseCaseProtocol {
    func publicAlbum(forLink link: String) async throws -> SharedAlbumEntity
    func publicPhotos(_ photos: [SetElementEntity]) async -> [NodeEntity]
}

public struct PublicAlbumUseCase<T: ShareAlbumRepositoryProtocol>: PublicAlbumUseCaseProtocol {
    private let shareAlbumRepository: T
    
    public init(shareAlbumRepository: T) {
        self.shareAlbumRepository = shareAlbumRepository
    }
    
    public func publicAlbum(forLink link: String) async throws -> SharedAlbumEntity {
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
}
