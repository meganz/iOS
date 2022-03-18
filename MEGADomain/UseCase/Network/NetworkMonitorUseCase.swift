
protocol NetworkMonitorUseCaseProtocol {
    func networkPathChanged(completion: @escaping (Bool) -> Void)
}

struct NetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    private let repo: NetworkMonitorRepositoryProtocol
    
    init(repo: NetworkMonitorRepositoryProtocol) {
        self.repo = repo
    }
    
    func networkPathChanged(completion: @escaping (Bool) -> Void) {
        repo.networkPathChanged(completion: completion)
    }
}
