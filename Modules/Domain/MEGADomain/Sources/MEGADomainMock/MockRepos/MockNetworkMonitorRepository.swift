import MEGADomain
import MEGASwift

public struct MockNetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    
    public static var newRepo: MockNetworkMonitorRepository {
        MockNetworkMonitorRepository()
    }
    
    public var connectionChangedStream: AnyAsyncSequence<Bool>
    public var connected: Bool
    public var connectedViaWiFi: Bool
    
    public init(connected: Bool = false,
                connectedViaWiFi: Bool = false,
                connectionChangedStream: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
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
