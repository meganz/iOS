import FileProvider
import MEGADomain

public protocol FileProviderItemMetadataRepositoryProtocol: RepositoryProtocol {
    func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber?
    func setFavoriteRank(for node: NSFileProviderItemIdentifier, with rank: NSNumber?)
    func tagData(for identifier: NSFileProviderItemIdentifier) -> Data?
    func setTagData(for identifier: NSFileProviderItemIdentifier, with data: Data?)
}
