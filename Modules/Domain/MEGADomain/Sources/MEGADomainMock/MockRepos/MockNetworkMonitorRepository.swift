import MEGADomain

public struct MockNetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    
    public let connectionChangedStream: AsyncStream<Bool>
    public var connected: Bool
    
    public init(connected: Bool = false,
                connectionChangedStream: AsyncStream<Bool> = AsyncStream<Bool> { $0.finish() }) {
        self.connected = connected
        self.connectionChangedStream = connectionChangedStream
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        completion(connected)
    }
    
    public func isConnected() -> Bool {
        connected
    }
}
