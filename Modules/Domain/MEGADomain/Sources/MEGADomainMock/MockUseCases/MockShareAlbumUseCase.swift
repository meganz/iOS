import MEGADomain

public struct MockShareAlbumUseCase: ShareAlbumUseCaseProtocol {
    
    private let shareAlbumLinkResult: Result<String, Error>
    private let shareAlbumsLinks: [HandleEntity: String]
    private let removeSharedAlbumLinkResult: Result<Void, Error>
    private let successfullyRemoveSharedAlbumLinkIds: [HandleEntity]
    private let doesAlbumsContainSensitiveElement: [HandleEntity: Bool]
    
    public init(shareAlbumLinkResult: Result<String, Error> = .failure(GenericErrorEntity()),
                shareAlbumsLinks: [HandleEntity: String] = [:],
                removeSharedAlbumLinkResult: Result<Void, Error> = .failure(GenericErrorEntity()),
                successfullyRemoveSharedAlbumLinkIds: [HandleEntity] = [HandleEntity](),
                doesAlbumsContainSensitiveElement: [HandleEntity: Bool] = [:]) {
        self.shareAlbumLinkResult = shareAlbumLinkResult
        self.shareAlbumsLinks = shareAlbumsLinks
        self.removeSharedAlbumLinkResult = removeSharedAlbumLinkResult
        self.successfullyRemoveSharedAlbumLinkIds = successfullyRemoveSharedAlbumLinkIds
        self.doesAlbumsContainSensitiveElement = doesAlbumsContainSensitiveElement
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
    
    public func doesAlbumsContainSensitiveElement(for albums: some Sequence<AlbumEntity>) async throws -> Bool {
        guard albums.contains(where: { album in doesAlbumsContainSensitiveElement[album.id] != nil }) else {
            // Mock has no data to compare against, therefore it should fail
            throw GenericErrorEntity()
        }
        return albums.contains { doesAlbumsContainSensitiveElement[$0.id] ?? false }
    }
}
