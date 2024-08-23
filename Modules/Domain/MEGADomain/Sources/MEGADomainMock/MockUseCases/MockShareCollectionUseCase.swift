import MEGADomain

public struct MockShareCollectionUseCase: ShareCollectionUseCaseProtocol {
    
    private let shareCollectionLinkResult: Result<String, Error>
    private let shareCollectionsLinks: [HandleEntity: String]
    private let removeSharedCollectionLinkResult: Result<Void, Error>
    private let successfullyRemoveSharedCollectionLinkIds: [HandleEntity]
    private let doesCollectionsContainSensitiveElement: [HandleEntity: Bool]
    
    public init(shareCollectionLinkResult: Result<String, Error> = .failure(GenericErrorEntity()),
                shareCollectionsLinks: [HandleEntity: String] = [:],
                removeSharedCollectionLinkResult: Result<Void, Error> = .failure(GenericErrorEntity()),
                successfullyRemoveSharedCollectionLinkIds: [HandleEntity] = [HandleEntity](),
                doesCollectionsContainSensitiveElement: [HandleEntity: Bool] = [:]) {
        self.shareCollectionLinkResult = shareCollectionLinkResult
        self.shareCollectionsLinks = shareCollectionsLinks
        self.removeSharedCollectionLinkResult = removeSharedCollectionLinkResult
        self.successfullyRemoveSharedCollectionLinkIds = successfullyRemoveSharedCollectionLinkIds
        self.doesCollectionsContainSensitiveElement = doesCollectionsContainSensitiveElement
    }
    
    public func shareCollectionLink(_ album: AlbumEntity) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: shareCollectionLinkResult)
        }
    }
    
    public func shareLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity: String] {
        shareCollectionsLinks
    }
    
    public func removeSharedLink(forAlbum album: AlbumEntity) async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: removeSharedCollectionLinkResult)
        }
    }
    
    public func removeSharedLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity] {
        successfullyRemoveSharedCollectionLinkIds
    }
    
    public func doesCollectionsContainSensitiveElement(for albums: some Sequence<AlbumEntity>) async throws -> Bool {
        guard albums.contains(where: { album in doesCollectionsContainSensitiveElement[album.id] != nil }) else {
            // Mock has no data to compare against, therefore it should fail
            throw GenericErrorEntity()
        }
        return albums.contains { doesCollectionsContainSensitiveElement[$0.id] ?? false }
    }
}
