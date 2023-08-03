import MEGADomain

public struct MockImportPublicAlbumUseCase: ImportPublicAlbumUseCaseProtocol {
    private let importAlbumResult: Result<Void, Error>
    
    public init(importAlbumResult: Result<Void, Error> = .failure(GenericErrorEntity())) {
        self.importAlbumResult = importAlbumResult
    }
    
    public func importAlbum(name: String, photos: [NodeEntity], parentFolder: NodeEntity) async throws {
        try await withCheckedThrowingContinuation {
            $0.resume(with: importAlbumResult)
        }
    }
}
