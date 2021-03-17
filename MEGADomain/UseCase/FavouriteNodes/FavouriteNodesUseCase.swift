
import Foundation

protocol FavouriteNodesUseCaseProtocol {
    func getAllFavouriteNodes(completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void)
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void)
}

struct FavouriteNodesUseCase: FavouriteNodesUseCaseProtocol {
    
    private let repo: FavouriteNodesRepositoryProtocol

    init(repo: FavouriteNodesRepositoryProtocol) {
        self.repo = repo
    }
    
    func getAllFavouriteNodes(completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.getAllFavouriteNodes(completion: completion)
    }
    
    func getFavouriteNodes(limitCount: Int, completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.getFavouriteNodes(limitCount: limitCount, completion: completion)
    }
}
