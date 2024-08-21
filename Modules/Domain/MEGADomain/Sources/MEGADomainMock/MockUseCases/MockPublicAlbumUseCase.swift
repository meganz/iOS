import MEGADomain

public final class MockPublicAlbumUseCase: PublicAlbumUseCaseProtocol {

    private let publicAlbumResult: Result<SharedCollectionEntity, Error>
    private let nodes: [NodeEntity]
    
    public private(set) var stopAlbumLinkPreviewCalled = 0
    
    public init(publicAlbumResult: Result<SharedCollectionEntity, Error> = .failure(GenericErrorEntity()),
                nodes: [NodeEntity] = []) {
        self.publicAlbumResult = publicAlbumResult
        self.nodes = nodes
    }
    
    public func publicAlbum(forLink link: String) async throws -> SharedCollectionEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: publicAlbumResult)
        }
    }
    
    public func publicPhotos(_ photos: [SetElementEntity]) async -> [NodeEntity] {
        nodes
    }
    
    public func stopAlbumLinkPreview() {
        stopAlbumLinkPreviewCalled += 1
    }
}
