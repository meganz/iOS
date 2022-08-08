import Foundation
@testable import MEGA
import MEGADomain

struct MockShareUseCase: ShareUseCaseProtocol {
    let nodes: [NodeEntity]
    let shares: [ShareEntity]
    
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        nodes
    }
    
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        shares
    }
}
