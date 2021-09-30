import Foundation
@testable import MEGA

struct MockAccountRepository: AccountRepositoryProtocol {
    let nodesCount: UInt
    
    var getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>) = .failure(.nodeNotFound)
    
    func totalNodesCount() -> UInt { nodesCount }
    
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }
}
