import MEGASwift

public protocol NetworkMonitorUseCaseProtocol: Sendable {
    /// Infinite `AnyAsyncSequence` returning results from network path monitoring.
    ///
    /// The stream will not finish and the task will need to be cancelled.
    /// - Returns: `AnyAsyncSequence<Bool>` indicating whether the connection is satisfied.
    var connectionSequence: AnyAsyncSequence<Bool> { get }
    
    /// Checks the current network connection status.
    ///
    /// This method synchronously returns the current network connection status.
    ///
    /// - Returns: `true` if the network connection is satisfied, `false` otherwise.
    func isConnected() -> Bool
    
    /// Checks if the current network connection is via WiFi.
    ///
    /// This method synchronously returns whether the network connection is using a WiFi interface.
    ///
    /// - Returns: `true` if the connection is via WiFi, `false` otherwise.
    func isConnectedViaWiFi() -> Bool
}

public struct NetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    private let repo: any NetworkMonitorRepositoryProtocol
    
    public var connectionSequence: AnyAsyncSequence<Bool> {
        repo.connectionSequence
    }
    
    public init(repo: some NetworkMonitorRepositoryProtocol) {
        self.repo = repo
    }
    
    public func isConnected() -> Bool {
        repo.isConnected()
    }
    
    public func isConnectedViaWiFi() -> Bool {
        repo.isConnectedViaWiFi()
    }
}
