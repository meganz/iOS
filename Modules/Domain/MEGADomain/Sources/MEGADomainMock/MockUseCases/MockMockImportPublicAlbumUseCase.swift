import MEGADomain

public final class MockImportPublicAlbumUseCase: ImportPublicAlbumUseCaseProtocol {
    private let importAlbumResult: Result<Void, Error>
    
    public private(set) var photosToImport: [NodeEntity]?
    
    public init(importAlbumResult: Result<Void, Error> = .failure(GenericErrorEntity())) {
        self.importAlbumResult = importAlbumResult
    }
    
    public func importAlbum(name: String, photos: [NodeEntity], parentFolder: NodeEntity) async throws {
        photosToImport = photos
        
        return try await withCheckedThrowingContinuation {
            $0.resume(with: importAlbumResult)
        }
    }
}
