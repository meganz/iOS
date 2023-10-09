import MEGADomain

public struct MockNetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    public static var newRepo: MockNetworkMonitorRepository {
        MockNetworkMonitorRepository()
    }
    
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
