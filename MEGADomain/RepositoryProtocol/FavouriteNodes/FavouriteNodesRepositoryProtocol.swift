import Foundation

protocol FavouriteNodesRepositoryProtocol {
    func getAllFavouriteNodes(completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void)
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void)
}
