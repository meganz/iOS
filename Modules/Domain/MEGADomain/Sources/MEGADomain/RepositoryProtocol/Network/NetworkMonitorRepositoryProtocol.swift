import MEGASwift

public protocol NetworkMonitorRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Asynchronous stream returning network connection status changes.
    ///
    /// The stream provides updates of type `Bool` indicating whether the network connection is satisfied.
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
