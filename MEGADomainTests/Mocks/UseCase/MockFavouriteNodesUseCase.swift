@testable import MEGA

final class MockFavouriteNodesUseCase: FavouriteNodesUseCaseProtocol {
    var getAllFavouriteNodesResult: Result<[NodeEntity], QuickAccessWidgetErrorEntity> = .failure(.generic)
    var getFavouriteNodesResult: Result<[NodeEntity], QuickAccessWidgetErrorEntity> = .failure(.generic)
    var onNodesUpdateCallback: [NodeEntity]? = [NodeEntity()]
    
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        completion(getAllFavouriteNodesResult)
    }
    
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        completion(getFavouriteNodesResult)
    }
    
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        guard let onNodesUpdateCallback = onNodesUpdateCallback else { return }
        callback(onNodesUpdateCallback)
    }
    
    func unregisterOnNodesUpdate() -> Void {
        onNodesUpdateCallback = nil
    }
}
