

struct PSAUseCase {
    private let repo: PSARepositoryProtocol
    
    init(repo: PSARepositoryProtocol) {
        self.repo = repo
    }
    
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        repo.getPSA(completion: completion)
    }
    
    func setPSA(withIdentifier identifier: PSAIdentifier) {
        repo.setPSA(withIdentifier: identifier)
    }
}
