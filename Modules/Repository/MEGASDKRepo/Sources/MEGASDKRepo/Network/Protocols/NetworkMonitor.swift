import Network

/// A protocol that abstracts the properties and methods of `NWPathMonitor`.
public protocol NetworkMonitor: Sendable {
    /// The current network path.
    var currentPath: NetworkPath { get }
    
    /// A stream of network path updates.
    var networkPathStream: AsyncStream<NetworkPath> { get }

    /// Starts monitoring the network path.
    func start()

    /// Stops monitoring the network path.
    func cancel()
}
