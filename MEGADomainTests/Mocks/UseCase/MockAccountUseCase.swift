@testable import MEGA

final class MockAccountUseCase: AccountUseCaseProtocol {
    var totalNodesCountVariable: UInt = 0
    var getMyChatFilesFolderResult: (Result<NodeEntity, AccountErrorEntity>) = .failure(.nodeNotFound)
    
    func totalNodesCount() -> UInt {
        totalNodesCountVariable
    }
    
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        completion(getMyChatFilesFolderResult)
    }
}
