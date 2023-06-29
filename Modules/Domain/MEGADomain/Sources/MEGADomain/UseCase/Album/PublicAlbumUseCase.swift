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
        let publicAlbumPhotoIds = try await shareAlbumRepository.publicAlbumContents(forLink: link)
            .setElements.map(\.id)
        return await publicPhotos(forPhotoIds: publicAlbumPhotoIds)
    }
    
    private func publicPhotos(forPhotoIds photoIds: [HandleEntity]) async -> [NodeEntity] {
        await withTaskGroup(of: NodeEntity?.self) { group in
            photoIds.forEach { photoId in
                group.addTask {
                    try? await shareAlbumRepository.publicPhoto(forPhotoId: photoId)
                }
            }
            return await group.reduce(into: [NodeEntity]()) {
                if let photo = $1 { $0.append(photo) }
            }
        }
    }
}
