import Combine
import MEGASwift

public protocol NetworkMonitorRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Infinite `AnyAsyncSequence` returning results from network path monitoring
    ///
    /// The stream will finish when the repository instance is deallocated
    /// - Returns: `AnyAsyncSequence<Bool>` whether the connection is satisfied
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
