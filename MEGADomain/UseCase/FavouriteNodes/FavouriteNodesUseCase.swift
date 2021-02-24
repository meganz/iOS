
import Foundation

protocol FavouriteNodesUseCaseProtocol {
    func favouriteNodes(completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void)
}

struct FavouriteNodesUseCase: FavouriteNodesUseCaseProtocol {
    
    private let repo: FavouriteNodesRepositoryProtocol

    init(repo: FavouriteNodesRepositoryProtocol) {
        self.repo = repo
    }
    
    func favouriteNodes(completion: @escaping (Result<[MEGANode], QuickAccessWidgetErrorEntity>) -> Void) {
        repo.favouriteNodes(completion: completion)
    }
}
