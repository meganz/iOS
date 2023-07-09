import MEGADomain

public struct MockPublicAlbumUseCase: PublicAlbumUseCaseProtocol {
    private let nodesResult: Result<[NodeEntity], Error>
    
    public init(nodesResult: Result<[NodeEntity], Error> = .failure(GenericErrorEntity())) {
        self.nodesResult = nodesResult
    }
    
    public func publicPhotos(forLink link: String) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: nodesResult)
        }
    }
}
