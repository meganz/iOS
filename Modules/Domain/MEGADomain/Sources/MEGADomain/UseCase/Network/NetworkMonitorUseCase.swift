
public protocol NetworkMonitorUseCaseProtocol {
    func networkPathChanged(completion: @escaping (Bool) -> Void)
    func isConnected() -> Bool
}

public struct NetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    private let repo: any NetworkMonitorRepositoryProtocol
    
    public init(repo: any NetworkMonitorRepositoryProtocol) {
        self.repo = repo
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        repo.networkPathChanged(completion: completion)
    }
    
    public func isConnected() -> Bool {
        repo.isConnected()
    }
}
