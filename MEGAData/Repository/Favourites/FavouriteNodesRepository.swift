import Foundation
import MEGADomain

final class FavouriteNodesRepository: NSObject, FavouriteNodesRepositoryProtocol {
    static var newRepo: FavouriteNodesRepository {
        FavouriteNodesRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    private var onNodesUpdate: (([NodeEntity]) -> Void)?
    private var favouritesNodesEntityArray: [NodeEntity]?
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    @available(*, renamed: "allFavouritesNodes()")
    func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        getFavouriteNodes(limitCount: 0, completion: completion)
    }
    
    func allFavouritesNodes() async throws -> [NodeEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            getFavouriteNodes(limitCount: 0) { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: GetFavouriteNodesErrorEntity.generic); return }
                
                continuation.resume(with: result)
            }
        }
    }
    
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        sdk.favourites(forParent: nil, count: limitCount, delegate: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                guard let favouritesHandleArray = request.megaHandleArray else {
                    return
                }
                let favouritesNodesArray = favouritesHandleArray.compactMap { handle -> NodeEntity? in
                    guard let node = self.sdk.node(forHandle: handle.uint64Value) else {
                        return nil
                    }
                    return node.toNodeEntity()
                }
                
                self.favouritesNodesEntityArray = favouritesNodesArray
                
                completion(.success(favouritesNodesArray))
                
            case .failure(_):
                completion(.failure(.sdk))
            }
        })
    }
    
    func allFavouriteNodes(searchString: String?, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        getFavouriteNodes(limitCount: 0) { result in
            switch result {
            case .success(let nodes):
                var filteredNodes = nodes
                if let searchString = searchString {
                    filteredNodes = filteredNodes.filter { $0.name.localizedCaseInsensitiveContains(searchString) == true }
                }
                completion(.success(filteredNodes))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        sdk.add(self)
        
        onNodesUpdate = callback
    }
    
    func unregisterOnNodesUpdate() {
        sdk.remove(self)
        
        onNodesUpdate = nil
    }
}

extension FavouriteNodesRepository: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let nodesUpdateArray = nodeList?.toNodeArray() else { return }
        var shouldProcessOnNodesUpdate: Bool = false
        
        var favouritesDictionary: Dictionary<String, String> = Dictionary()
        self.favouritesNodesEntityArray?.forEach({ nodeEntity in
            favouritesDictionary[nodeEntity.base64Handle] = nodeEntity.base64Handle
        })
        
        for nodeUpdated in nodesUpdateArray {
            if let base64Handle = nodeUpdated.base64Handle,
               (nodeUpdated.hasChangedType(.attributes) || favouritesDictionary[base64Handle] != nil) {
                shouldProcessOnNodesUpdate = true
                break
            }
        }
        
        if shouldProcessOnNodesUpdate {
            guard let nodeEntities = nodeList?.toNodeEntities() else { return }
            self.onNodesUpdate?(nodeEntities)
        }
    }
}
