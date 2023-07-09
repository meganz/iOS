import Foundation

public protocol PublicAlbumUseCaseProtocol {
    func publicPhotos(forLink link: String) async throws -> [NodeEntity]
}

public struct PublicAlbumUseCase<T: ShareAlbumRepositoryProtocol>: PublicAlbumUseCaseProtocol {
    private let shareAlbumRepository: T
    
    public init(shareAlbumRepository: T) {
        self.shareAlbumRepository = shareAlbumRepository
    }
    
    public func publicPhotos(forLink link: String) async throws -> [NodeEntity] {
        let publicAlbumPhotos = try await shareAlbumRepository.publicAlbumContents(forLink: link)
            .setElements
        return await withTaskGroup(of: NodeEntity?.self) { group in
            publicAlbumPhotos.forEach { photoElement in
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
