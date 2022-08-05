import Foundation
@testable import MEGA
import MEGADomain

struct MockAccountRepository: AccountRepositoryProtocol {
    let nodesCount: UInt
    
    var getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>) = .failure(.nodeNotFound)
    
    var accountDetails: (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) = .failure(.generic)
    
    func totalNodesCount() -> UInt { nodesCount }
    
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }
    
    func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void) {
        completion(accountDetails)
    }
}
