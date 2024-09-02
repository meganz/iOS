import MEGADomain
import MEGASwift

public final class MockPublicCollectionUseCase: PublicCollectionUseCaseProtocol, @unchecked Sendable {

    private let publicAlbumResult: Result<SharedCollectionEntity, Error>
    private let nodes: [NodeEntity]
    
    @Atomic public var stopCollectionLinkPreviewCalled = 0
    
    public init(publicAlbumResult: Result<SharedCollectionEntity, Error> = .failure(GenericErrorEntity()),
                nodes: [NodeEntity] = []) {
        self.publicAlbumResult = publicAlbumResult
        self.nodes = nodes
    }
    
    public func publicCollection(forLink link: String) async throws -> SharedCollectionEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: publicAlbumResult)
        }
    }
    
    public func publicNodes(_ elements: [SetElementEntity]) async -> [NodeEntity] {
        nodes
    }
    
    public func stopCollectionLinkPreview() {
        $stopCollectionLinkPreviewCalled.mutate { $0 += 1 }
    }
}
