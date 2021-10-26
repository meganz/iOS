import Foundation

struct AccountRepository: AccountRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        sdk.getMyChatFilesFolder(with: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                guard let node = sdk.node(forHandle: request.nodeHandle) else {
                    completion(.failure(AccountErrorEntity.generic))
                    return
                }
                completion(.success(NodeEntity(node: node)))
                
            case .failure(_):
                completion(.failure(AccountErrorEntity.nodeNotFound))
            }
        })
    }
    
    func totalNodesCount() -> UInt {
        sdk.totalNodes
    }
    
    func getAccountDetails(completion: @escaping (Result<AccountDetailsEntity, AccountDetailsErrorEntity>) -> Void) {
        sdk.getAccountDetails(with: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                completion(.success(AccountDetailsEntity(accountDetails: request.megaAccountDetails)))
            case .failure:
                completion(.failure(.generic))
            }
        })
    }
}
