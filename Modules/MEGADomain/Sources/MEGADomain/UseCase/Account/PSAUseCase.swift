
public protocol PSAUseCaseProtocol {
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void)
    func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier)
}

public struct PSAUseCase<T: PSARepositoryProtocol>: PSAUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        repo.getPSA(completion: completion)
    }
    
    public func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier) {
        repo.markAsSeenForPSA(withIdentifier: identifier)
    }
}
