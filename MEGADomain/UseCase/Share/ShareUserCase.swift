import Foundation
import MEGADomain

protocol ShareUseCaseProtocol {
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity]
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity]
}

struct ShareUseCase<T: ShareRepositoryProtocol>: ShareUseCaseProtocol {
    private let repo: T
    init(repo: T) {
        self.repo = repo
    }
    
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        repo.allPublicLinks(sortBy: order)
    }
    
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        repo.allOutShares(sortBy: order)
    }
}
