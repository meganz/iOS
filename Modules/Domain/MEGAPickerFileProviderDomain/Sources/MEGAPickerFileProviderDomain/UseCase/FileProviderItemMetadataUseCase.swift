import FileProvider

public protocol FileProviderItemMetadataUseCaseProtocol {
    func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber?
    func setFavoriteRank(for node: NSFileProviderItemIdentifier, with rank: NSNumber?)
    func tagData(for identifier: NSFileProviderItemIdentifier) -> Data?
    func setTagData(for identifier: NSFileProviderItemIdentifier, with data: Data?)
}

public struct FileProviderItemMetadataUseCase: FileProviderItemMetadataUseCaseProtocol {
    private let repository: any FileProviderItemMetadataRepositoryProtocol

    public init(repository: any FileProviderItemMetadataRepositoryProtocol) {
        self.repository = repository
    }

    public func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber? {
        repository.favoriteRank(for: identifier)
    }

    public func setFavoriteRank(for identifier: NSFileProviderItemIdentifier, with rank: NSNumber?) {
        repository.setFavoriteRank(for: identifier, with: rank)
    }

    public func tagData(for identifier: NSFileProviderItemIdentifier) -> Data? {
        repository.tagData(for: identifier)
    }

    public func setTagData(for identifier: NSFileProviderItemIdentifier, with data: Data?) {
        repository.setTagData(for: identifier, with: data)
    }
}
