import Network

/// A class that adapts the real `NWPathMonitor` to the `NetworkMonitor` protocol.
public class NWPathMonitorWrapper: NetworkMonitor, @unchecked Sendable {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var continuation: AsyncStream<NetworkPath>.Continuation?
    
    public var currentPath: NetworkPath {
        monitor.currentPath
    }
    
    public var networkPathStream: AsyncStream<NetworkPath> {
        AsyncStream { continuation in
            self.continuation = continuation
            
            self.monitor.pathUpdateHandler = { path in
                continuation.yield(path)
            }

            continuation.onTermination = { @Sendable _ in
                self.cancel()
            }
        }
    }

    /// Initialises a new instance of `NWPathMonitorWrapper`.
    /// - Parameters:
    ///   - monitor: The `NWPathMonitor` instance to adapt.
    ///   - queue: The `DispatchQueue` to run the monitor on.
    public init(
        monitor: NWPathMonitor = NWPathMonitor(),
        queue: DispatchQueue = DispatchQueue(label: "NetworkMonitor")
    ) {
        self.monitor = monitor
        self.queue = queue
        
        start()
    }
    
    public func start() {
        monitor.start(queue: queue)
    }

    public func cancel() {
        monitor.cancel()
        continuation?.finish()
    }
}
