import Foundation
import MEGADomain

struct ShareRepository: ShareRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        sdk.publicLinks(order.toMEGASortOrderType())
            .toNodeEntities()
    }

    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        sdk.outShares(order.toMEGASortOrderType()).toShareEntities()
    }
}
