import Foundation

protocol FavouriteNodesRepositoryProtocol {
    func favouriteNodes(completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void)
}
