import Foundation

public protocol FavouriteNodesRepositoryProtocol: RepositoryProtocol, Sendable {
    func allFavouritesNodes(searchString: String?, limit: Int) async throws -> [NodeEntity]
    func allFavouritesNodes(limit: Int) async throws -> [NodeEntity]
}
