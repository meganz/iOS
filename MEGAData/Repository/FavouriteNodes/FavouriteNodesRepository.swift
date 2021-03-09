import Foundation

struct FavouriteNodesRepository: FavouriteNodesRepositoryProtocol {
    
    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func favouriteNodes(completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        sdk.favourites(forParent: nil, count: 0, delegate: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                guard let favouritesHandleArray = request.megaHandleArray else {
                    return
                }
                let favouritesNodesArray = favouritesHandleArray.compactMap { handle -> NodeEntity? in
                    guard let node = sdk.node(forHandle: handle.uint64Value) else {
                        return nil
                    }
                    return NodeEntity(with: node)
                }
                
                completion(.success(favouritesNodesArray))
            case .failure(_):
                completion(.failure(.sdk))
            }
        })
    }

}
