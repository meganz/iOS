import Foundation

struct FavouriteNodesRepository: FavouriteNodesRepositoryProtocol {
    
    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func getAllFavouriteNodes(completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void) {
        getFavouriteNodes(limitCount: 0, completion: completion)
    }
    
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void) {
        sdk.favourites(forParent: nil, count: limitCount, delegate: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                guard let favouritesHandleArray = request.megaHandleArray else {
                    return
                }
                let favouritesNodesArray = favouritesHandleArray.compactMap { sdk.node(forHandle: $0.uint64Value)}
                
                completion(.success(favouritesNodesArray))
            case .failure(_):
                completion(.failure(.sdk))
            }
        })
    }

}
