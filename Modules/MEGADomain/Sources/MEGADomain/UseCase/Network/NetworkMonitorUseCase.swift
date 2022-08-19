
public protocol NetworkMonitorUseCaseProtocol {
    func networkPathChanged(completion: @escaping (Bool) -> Void)
}

public struct NetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    private let repo: NetworkMonitorRepositoryProtocol
    
    public init(repo: NetworkMonitorRepositoryProtocol) {
        self.repo = repo
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        repo.networkPathChanged(completion: completion)
    }
}
