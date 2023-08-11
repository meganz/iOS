import FileProvider
import MEGADomain

public protocol FilesAppFavoriteRankRepositoryProtocol: RepositoryProtocol {
    func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber?
    func setFavoriteRank(for identifier: NSFileProviderItemIdentifier, with rank: NSNumber?)
}
