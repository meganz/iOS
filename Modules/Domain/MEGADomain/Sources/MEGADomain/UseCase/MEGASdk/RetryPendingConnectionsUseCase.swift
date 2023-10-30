public protocol RetryPendingConnectionsUseCaseProtocol {
    func retryPendingConnections()
}

public struct RetryPendingConnectionsUseCase<T: RetryPendingConnectionsRepositoryProtocol>: RetryPendingConnectionsUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func retryPendingConnections() {
        repo.retryPendingConnections()
    }
}
