import Foundation
import MEGADomain

struct AccountRepository: AccountRepositoryProtocol {
    static var newRepo: AccountRepository {
        AccountRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        MyChatFilesFolderNodeAccess.shared.loadNode { myChatFilesFolderNode, error in
            guard let myChatFilesFolderNode = myChatFilesFolderNode else {
                completion(.failure(AccountErrorEntity.nodeNotFound))
                return
            }
            
            completion(.success(myChatFilesFolderNode.toNodeEntity()))
        }
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
    
    func upgradeSecurity() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.upgradeSecurity(with: RequestDelegate { (result) in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure:
                    continuation.resume(throwing: AccountErrorEntity.generic)
                }
            })
        }
    }
}
