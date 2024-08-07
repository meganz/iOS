import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public final class FavouriteNodesRepository: NSObject, FavouriteNodesRepositoryProtocol, @unchecked Sendable {
    
    public static var newRepo: FavouriteNodesRepository {
        FavouriteNodesRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    @Atomic private var onNodesUpdate: (([NodeEntity]) -> Void)?
    @Atomic private var favouritesNodesEntityArray: [NodeEntity]?
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    @available(*, renamed: "allFavouritesNodes()")
    public func getAllFavouriteNodes(completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        getFavouriteNodes(limitCount: 0, completion: completion)
    }
    
    public func allFavouritesNodes(limit: Int) async throws -> [NodeEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            getFavouriteNodes(limitCount: limit) { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: GetFavouriteNodesErrorEntity.generic); return }
                
                continuation.resume(with: result)
            }
        }
    }
        
    public func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
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
                
                self.$favouritesNodesEntityArray.mutate { $0 = favouritesNodesArray }
                
                completion(.success(favouritesNodesArray))
                
            case .failure:
                completion(.failure(.sdk))
            }
        })
    }
    
    public func allFavouriteNodes(searchString: String?, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
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
    
    public func allFavouritesNodes(searchString: String?, limit: Int) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation { continuation in
            allFavouriteNodes(searchString: searchString) { continuation.resume(with: $0) }
        }
    }
    
    public func registerOnNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        sdk.add(self)
        
        $onNodesUpdate.mutate { $0 = callback }
    }
    
    public func unregisterOnNodesUpdate() {
        sdk.remove(self)
        
        $onNodesUpdate.mutate { $0 = nil }
    }
}

extension FavouriteNodesRepository: MEGAGlobalDelegate {
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let nodesUpdateArray = nodeList?.toNodeArray() else { return }
        var shouldProcessOnNodesUpdate: Bool = false
        
        var favouritesDictionary = [String: String]()
        self.favouritesNodesEntityArray?.forEach({ nodeEntity in
            favouritesDictionary[nodeEntity.base64Handle] = nodeEntity.base64Handle
        })
        
        for nodeUpdated in nodesUpdateArray {
            if let base64Handle = nodeUpdated.base64Handle,
               nodeUpdated.hasChangedType(.attributes) || favouritesDictionary[base64Handle] != nil {
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
