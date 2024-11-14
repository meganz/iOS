import MEGADomain

public struct MockPSARepository: PSARepositoryProtocol {
    public static var newRepo: MockPSARepository {
        MockPSARepository()
    }
    
    let psaResult: Result<PSAEntity, PSAErrorEntity>
    
    public init(psaResult: Result<PSAEntity, PSAErrorEntity> = .failure(.generic)) {
        self.psaResult = psaResult
    }
    
    public func getPSA() async throws -> PSAEntity {
        try psaResult.get()
    }
    
    public func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier) { }
}
