public protocol NetworkMonitorUseCaseProtocol {
    /// Infinite `AsyncStream` returning results from network path monitoring
    ///
    /// The stream will not finish and the task will need to be cancelled
    /// - Returns: `AsyncStream` whether the connection is satisfied
    var connectionChangedStream: AsyncStream<Bool> { get }
    func networkPathChanged(completion: @escaping (Bool) -> Void)
    func isConnected() -> Bool
}

public struct NetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    private let repo: any NetworkMonitorRepositoryProtocol
    public let connectionChangedStream: AsyncStream<Bool>
    
    public init(repo: some NetworkMonitorRepositoryProtocol) {
        self.repo = repo
        connectionChangedStream = repo.connectionChangedStream
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        repo.networkPathChanged(completion: completion)
    }
    
    public func isConnected() -> Bool {
        repo.isConnected()
    }
}
