import MEGADomain

public struct MockShareAlbumUseCase: ShareAlbumUseCaseProtocol {
    private let shareAlbumLinkResult: Result<String, Error>
    private let removeSharedAlbumLinkResult: Result<Void, Error>
    
    public init(shareAlbumLinkResult: Result<String, Error> = .failure(GenericErrorEntity()),
                removeSharedAlbumLinkResult: Result<Void, Error> = .failure(GenericErrorEntity())) {
        self.shareAlbumLinkResult = shareAlbumLinkResult
        self.removeSharedAlbumLinkResult = removeSharedAlbumLinkResult
    }
    
    public func shareAlbumLink(_ album: AlbumEntity) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: shareAlbumLinkResult)
        }
    }
    
    public func removeSharedLink(forAlbum album: AlbumEntity) async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: removeSharedAlbumLinkResult)
        }
    }
}
