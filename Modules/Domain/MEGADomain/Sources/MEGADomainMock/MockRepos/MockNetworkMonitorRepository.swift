import MEGADomain
import MEGASwift

public struct MockNetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    public static var newRepo: MockNetworkMonitorRepository {
        MockNetworkMonitorRepository()
    }
    public let connectionSequence: AnyAsyncSequence<Bool>
    public let connected: Bool
    public let connectedViaWiFi: Bool
    
    public init(
        connected: Bool = false,
        connectedViaWiFi: Bool = false,
        connectionSequence: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.connected = connected
        self.connectedViaWiFi = connectedViaWiFi
        self.connectionSequence = connectionSequence
    }
    
    public func isConnected() -> Bool {
        connected
    }
    
    public func isConnectedViaWiFi() -> Bool {
        connectedViaWiFi
    }
}
