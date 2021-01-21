

struct PSAUseCase {
    private let repo: PSARepositoryProtocol
    
    init(repo: PSARepositoryProtocol) {
        self.repo = repo
    }
    
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        repo.getPSA(completion: completion)
    }
    
    func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier) {
        repo.markAsSeenForPSA(withIdentifier: identifier)
    }
}
