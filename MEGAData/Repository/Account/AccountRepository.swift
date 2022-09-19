import Foundation
import MEGADomain

struct AccountRepository: AccountRepositoryProtocol {
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
    
    func inboxNode() -> NodeEntity? {
        sdk.inboxNode?.toNodeEntity()
    }
    
    func existsBackupNode() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            BackupRootNodeAccess.shared.loadNode { node, error in
                guard node != nil else {
                    continuation.resume(throwing: BackupNodeErrorEntity.notFound)
                    return
                }
                continuation.resume(with: Result.success(true))
            }
        }
    }
}
