import MEGASwift

public protocol NetworkMonitorUseCaseProtocol {
    /// Infinite `AnyAsyncSequence` returning results from network path monitoring
    ///
    /// The stream will not finish and the task will need to be cancelled
    /// - Returns: `AnyAsyncSequence<Bool>` whether the connection is satisfied
    var connectionChangedStream: AnyAsyncSequence<Bool> { get }
    func networkPathChanged(completion: @escaping (Bool) -> Void)
    func isConnected() -> Bool
    func isConnectedViaWiFi() -> Bool
}

public struct NetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    private let repo: any NetworkMonitorRepositoryProtocol
    
    public var connectionChangedStream: AnyAsyncSequence<Bool> {
        repo.connectionChangedStream
    }
    
    public init(repo: some NetworkMonitorRepositoryProtocol) {
        self.repo = repo
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        repo.networkPathChanged(completion: completion)
    }
    
    public func isConnected() -> Bool {
        repo.isConnected()
    }
    
    public func isConnectedViaWiFi() -> Bool {
        repo.isConnectedViaWiFi()
    }
}
