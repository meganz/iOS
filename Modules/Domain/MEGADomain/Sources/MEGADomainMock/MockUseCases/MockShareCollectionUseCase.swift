import MEGADomain

public struct MockShareCollectionUseCase: ShareCollectionUseCaseProtocol {
    
    private let shareCollectionLinkResult: Result<String, any Error>
    private let shareCollectionsLinks: [SetIdentifier: String]
    private let removeSharedCollectionLinkResult: Result<Void, any Error>
    private let successfullyRemoveSharedCollectionLinkIds: [SetIdentifier]
    private let doesCollectionsContainSensitiveElement: [HandleEntity: Bool]
    
    public init(shareCollectionLinkResult: Result<String, any Error> = .failure(GenericErrorEntity()),
                shareCollectionsLinks: [SetIdentifier: String] = [:],
                removeSharedCollectionLinkResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
                successfullyRemoveSharedCollectionLinkIds: [SetIdentifier] = [SetIdentifier](),
                doesCollectionsContainSensitiveElement: [HandleEntity: Bool] = [:]) {
        self.shareCollectionLinkResult = shareCollectionLinkResult
        self.shareCollectionsLinks = shareCollectionsLinks
        self.removeSharedCollectionLinkResult = removeSharedCollectionLinkResult
        self.successfullyRemoveSharedCollectionLinkIds = successfullyRemoveSharedCollectionLinkIds
        self.doesCollectionsContainSensitiveElement = doesCollectionsContainSensitiveElement
    }
    
    public func shareCollectionLink(_ collection: SetEntity) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: shareCollectionLinkResult)
        }
    }
    
    public func shareLink(forCollections collections: [SetEntity]) async -> [SetIdentifier: String] {
        shareCollectionsLinks
    }
    
    public func removeSharedLink(forCollectionId collectionId: SetIdentifier) async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: removeSharedCollectionLinkResult)
        }
    }
    
    public func removeSharedLink(forCollections collectionIds: [SetIdentifier]) async -> [SetIdentifier] {
        successfullyRemoveSharedCollectionLinkIds
    }
    
    public func doesCollectionsContainSensitiveElement(for collections: some Sequence<SetEntity>) async throws -> Bool {
        guard collections.contains(where: { collection in doesCollectionsContainSensitiveElement[collection.handle] != nil }) else {
            // Mock has no data to compare against, therefore it should fail
            throw GenericErrorEntity()
        }
        return collections.contains { doesCollectionsContainSensitiveElement[$0.handle] ?? false }
    }
}
