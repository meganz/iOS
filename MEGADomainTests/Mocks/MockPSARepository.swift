@testable import MEGA

struct MockPSARepository: PSARepositoryProtocol {
    var psaResult: Result<PSAEntity, PSAErrorEntity> = .failure(.generic)
    
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        completion(psaResult)
    }
    
    func markAsSeenForPSA(withIdentifier identifier: Int) { }
}
