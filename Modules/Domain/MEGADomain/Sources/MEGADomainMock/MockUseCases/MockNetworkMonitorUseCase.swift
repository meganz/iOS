import MEGADomain
import MEGASwift

public struct MockNetworkMonitorUseCase: NetworkMonitorUseCaseProtocol, Sendable {
    private let connected: Bool
    private let connectedViaWiFi: Bool
    public let connectionSequence: AnyAsyncSequence<Bool>

    public init(
        connected: Bool = true,
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
