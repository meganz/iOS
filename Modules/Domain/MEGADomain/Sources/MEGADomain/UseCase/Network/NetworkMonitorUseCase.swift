import Combine
import MEGASwift

public protocol NetworkMonitorUseCaseProtocol {
    /// Infinite `AnyAsyncSequence` returning results from network path monitoring
    ///
    /// The stream will not finish and the task will need to be cancelled.
    /// - Returns: `AnyAsyncSequence<Bool>` whether the connection is satisfied.
    var connectionChangedStream: AnyAsyncSequence<Bool> { get }
    
    /// Publisher that emits a boolean indicating the network connection status whenever it changes.
    var networkPathChangedPublisher: AnyPublisher<Bool, Never> { get }
    
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
    
    public var connectionChangedStream: AnyAsyncSequence<Bool> {
        repo.connectionChangedStream
    }
    
    public var networkPathChangedPublisher: AnyPublisher<Bool, Never> {
        repo.networkPathChangedPublisher
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
