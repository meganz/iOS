
import Foundation

protocol FavouriteNodesUseCaseProtocol {
    func favouriteNodes(completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void)
}

struct FavouriteNodesUseCase: FavouriteNodesUseCaseProtocol {
    
    private let repo: FavouriteNodesRepositoryProtocol

    init(repo: FavouriteNodesRepositoryProtocol) {
        self.repo = repo
    }
    
    func favouriteNodes(completion: @escaping (Result<[NodeEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.favouriteNodes(completion: completion)
    }
}
