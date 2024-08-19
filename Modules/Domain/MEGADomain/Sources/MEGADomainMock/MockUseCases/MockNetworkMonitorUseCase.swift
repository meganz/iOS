import Combine
import MEGADomain
import MEGASwift

public struct MockNetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    
    private let connected: Bool
    private let connectedViaWiFi: Bool
    public let connectionChangedStream: AnyAsyncSequence<Bool>
    public let networkPathChangedPublisher: AnyPublisher<Bool, Never>

    public init(
        connected: Bool = true,
        connectedViaWiFi: Bool = false,
        connectionChangedStream: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        networkPathChangedPublisher: AnyPublisher<Bool, Never> = Just(true).eraseToAnyPublisher()
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
