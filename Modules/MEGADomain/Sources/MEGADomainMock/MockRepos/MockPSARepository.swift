import MEGADomain

public struct MockPSARepository: PSARepositoryProtocol {
    public static var newRepo: MockPSARepository {
        MockPSARepository()
    }
    
    let psaResult: Result<PSAEntity, PSAErrorEntity>
    
    public init(psaResult: Result<PSAEntity, PSAErrorEntity> = .failure(.generic)) {
        self.psaResult = psaResult
    }
    
    public func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        completion(psaResult)
    }
    
    public func markAsSeenForPSA(withIdentifier identifier: Int) { }
}
