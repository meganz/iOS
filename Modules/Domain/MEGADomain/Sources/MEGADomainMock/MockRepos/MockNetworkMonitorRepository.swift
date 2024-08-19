@preconcurrency import Combine
import MEGADomain
import MEGASwift

public struct MockNetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    public static var newRepo: MockNetworkMonitorRepository {
        MockNetworkMonitorRepository()
    }
    
    public var connectionChangedStream: AnyAsyncSequence<Bool>
    public var networkPathChangedPublisher: AnyPublisher<Bool, Never>
    public var connected: Bool
    public var connectedViaWiFi: Bool
    
    public init(
        connected: Bool = false,
        connectedViaWiFi: Bool = false,
        connectionChangedStream: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        networkPathChangedPublisher: AnyPublisher<Bool, Never> = Just(false).eraseToAnyPublisher()
    ) {
        self.connected = connected
        self.connectedViaWiFi = connectedViaWiFi
        self.connectionChangedStream = connectionChangedStream
        self.networkPathChangedPublisher = networkPathChangedPublisher
    }
    
    public func isConnected() -> Bool {
        connected
    }
    
    public func isConnectedViaWiFi() -> Bool {
        connectedViaWiFi
    }
}
