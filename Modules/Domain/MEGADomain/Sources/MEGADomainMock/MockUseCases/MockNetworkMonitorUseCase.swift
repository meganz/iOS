import MEGADomain

public struct MockNetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    private let connected: Bool
    public let connectionChangedStream: AsyncStream<Bool>
    
    public init(connected: Bool = true,
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
