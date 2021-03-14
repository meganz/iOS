import Foundation

protocol FavouriteNodesRepositoryProtocol {
    func favouriteNodes(completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void)
}
