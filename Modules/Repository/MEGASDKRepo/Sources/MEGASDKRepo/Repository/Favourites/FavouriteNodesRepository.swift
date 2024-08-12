import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public final class FavouriteNodesRepository: NSObject, FavouriteNodesRepositoryProtocol, @unchecked Sendable {
    
    public static var newRepo: FavouriteNodesRepository {
        FavouriteNodesRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func allFavouritesNodes(limit: Int) async throws -> [NodeEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            getFavouriteNodes(limitCount: limit) { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: GetFavouriteNodesErrorEntity.generic); return }
                
                continuation.resume(with: result)
            }
        }
    }
    
    public func allFavouritesNodes(searchString: String?, limit: Int) async throws -> [NodeEntity] {
        try await withAsyncThrowingValue{ completion in
            allFavouriteNodes(searchString: searchString) { completion($0.mapError { $0 as any Error }) }
        }
    }
        
    private func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        sdk.favourites(forParent: nil, count: limitCount, delegate: RequestDelegate { [weak sdk] (result) in
            switch result {
            case .success(let request):
                guard 
                    let sdk,
                    let favouritesHandleArray = request.megaHandleArray else {
                    return
                }
                let favouritesNodesArray: [NodeEntity] = favouritesHandleArray
                    .compactMap { handle -> NodeEntity? in
                        sdk.node(forHandle: handle.uint64Value)?.toNodeEntity()
                    }
                                
                completion(.success(favouritesNodesArray))
                
            case .failure:
                completion(.failure(.sdk))
            }
        })
    }
    
    private func allFavouriteNodes(searchString: String?, completion: @escaping (Result<[NodeEntity], GetFavouriteNodesErrorEntity>) -> Void) {
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

}
