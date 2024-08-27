import MEGADomain
import MEGASwift

public final class MockImportPublicAlbumUseCase: ImportPublicAlbumUseCaseProtocol, @unchecked Sendable {
    private let importAlbumResult: Result<Void, Error>
    
    @Atomic public var photosToImport: [NodeEntity]?
    
    public init(importAlbumResult: Result<Void, Error> = .failure(GenericErrorEntity())) {
        self.importAlbumResult = importAlbumResult
    }
    
    public func importAlbum(name: String, photos: [NodeEntity], parentFolder: NodeEntity) async throws {
        $photosToImport.mutate { $0 = photos }
        
        return try await withCheckedThrowingContinuation {
            $0.resume(with: importAlbumResult)
        }
    }
}
