import MEGADomain

public struct MockPublicAlbumUseCase: PublicAlbumUseCaseProtocol {
    private let publicAlbumResult: Result<SharedAlbumEntity, Error>
    private let nodes: [NodeEntity]
    
    public init(publicAlbumResult: Result<SharedAlbumEntity, Error> = .failure(GenericErrorEntity()),
                nodes: [NodeEntity] = []) {
        self.publicAlbumResult = publicAlbumResult
        self.nodes = nodes
    }
    
    public func publicAlbum(forLink link: String) async throws -> SharedAlbumEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: publicAlbumResult)
        }
    }
    
    public func publicPhotos(_ photos: [SetElementEntity]) async -> [NodeEntity] {
        nodes
    }
}
