import Foundation

struct FavouriteNodesRepository: FavouriteNodesRepositoryProtocol {
    
    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func favouriteNodes(completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void) {
        sdk.favourites(forParent: nil, count: 0, delegate: RequestDelegate { (result) in
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
