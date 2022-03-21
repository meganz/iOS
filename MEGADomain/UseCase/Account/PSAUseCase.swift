
protocol PSAUseCaseProtocol {
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void)
    func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier)
}

struct PSAUseCase<T: PSARepositoryProtocol>: PSAUseCaseProtocol {
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        repo.getPSA(completion: completion)
    }
    
    func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier) {
        repo.markAsSeenForPSA(withIdentifier: identifier)
    }
}
