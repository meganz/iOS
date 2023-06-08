import MEGADomain

public struct MockShareAlbumUseCase: ShareAlbumUseCaseProtocol {
    private let shareAlbumLinkResult: Result<String, Error>
    private let shareAlbumsLinks: [HandleEntity: String]
    private let removeSharedAlbumLinkResult: Result<Void, Error>
    private let successfullyRemoveSharedAlbumLinkIds: [HandleEntity]
    
    public init(shareAlbumLinkResult: Result<String, Error> = .failure(GenericErrorEntity()),
                shareAlbumsLinks: [HandleEntity: String] = [:],
                removeSharedAlbumLinkResult: Result<Void, Error> = .failure(GenericErrorEntity()),
                successfullyRemoveSharedAlbumLinkIds: [HandleEntity] = [HandleEntity]()) {
        self.shareAlbumLinkResult = shareAlbumLinkResult
        self.shareAlbumsLinks = shareAlbumsLinks
        self.removeSharedAlbumLinkResult = removeSharedAlbumLinkResult
        self.successfullyRemoveSharedAlbumLinkIds = successfullyRemoveSharedAlbumLinkIds
    }
    
    public func shareAlbumLink(_ album: AlbumEntity) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: shareAlbumLinkResult)
        }
    }
    
    public func shareLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity: String] {
        shareAlbumsLinks
    }
    
    public func removeSharedLink(forAlbum album: AlbumEntity) async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: removeSharedAlbumLinkResult)
        }
    }
    
    public func removeSharedLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity] {
        successfullyRemoveSharedAlbumLinkIds
    }
}
