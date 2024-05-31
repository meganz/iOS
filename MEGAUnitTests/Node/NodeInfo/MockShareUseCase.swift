import MEGADomain
import XCTest

final class MockShareUseCase: ShareUseCaseProtocol {
    var allPublicLinksResult: [NodeEntity] = []
    var allOutSharesResult: [ShareEntity] = []
    var areCredentialsVerifedResult: Bool = false
    var userResult: UserEntity?
    var createShareKeysResult: [HandleEntity] = []
    var createShareKeysError: Error?
    var userFunctionHasBeenCalled = false
    var createShareKeyFunctionHasBeenCalled = false
    
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        return allPublicLinksResult
    }
    
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        return allOutSharesResult
    }
    
    func areCredentialsVerifed(of user: UserEntity) -> Bool {
        return areCredentialsVerifedResult
    }
    
    func user(from node: NodeEntity) -> UserEntity? {
        userFunctionHasBeenCalled = true
        return userResult
    }
    
    func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity] {
        createShareKeyFunctionHasBeenCalled = true
        
        if let error = createShareKeysError {
            throw error
        }
        
        return createShareKeysResult
    }
}
