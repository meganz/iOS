import Foundation
import MEGADomain

protocol ShareRepositoryProtocol {
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity]
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity]
}
