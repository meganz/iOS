import FileProvider

public protocol FilesAppFavoriteRankUseCaseProtocol {
    func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber?
    func setFavoriteRank(for node: NSFileProviderItemIdentifier, with rank: NSNumber?)
}

public struct FilesAppFavoriteRankUseCase: FilesAppFavoriteRankUseCaseProtocol {
    private let repository: any FilesAppFavoriteRankRepositoryProtocol

    public init(repository: any FilesAppFavoriteRankRepositoryProtocol) {
        self.repository = repository
    }

    public func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber? {
        repository.favoriteRank(for: identifier)
    }

    public func setFavoriteRank(for identifier: NSFileProviderItemIdentifier, with rank: NSNumber?) {
        repository.setFavoriteRank(for: identifier, with: rank)
    }
}
