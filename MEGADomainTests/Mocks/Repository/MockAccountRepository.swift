import Foundation
@testable import MEGA

struct MockAccountRepository: AccountRepositoryProtocol {
    let nodesCount: UInt
    
    func totalNodesCount() -> UInt { nodesCount }
}
