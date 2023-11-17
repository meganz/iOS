import MEGADomain

public struct MockNetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    private let connected: Bool
    private let connectedViaWiFi: Bool
    public let connectionChangedStream: AsyncStream<Bool>
    
    public init(connected: Bool = true,
                connectedViaWiFi: Bool = false,
                connectionChangedStream: AsyncStream<Bool> = AsyncStream<Bool> { $0.finish() }) {
        self.connected = connected
        self.connectedViaWiFi = connectedViaWiFi
        self.connectionChangedStream = connectionChangedStream
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        completion(connected)
    }
    
    public func isConnected() -> Bool {
        connected
    }
    
    public func isConnectedViaWiFi() -> Bool {
        connectedViaWiFi
    }
}
