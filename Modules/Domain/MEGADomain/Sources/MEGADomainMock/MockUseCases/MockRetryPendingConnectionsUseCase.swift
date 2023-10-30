import MEGADomain

public final class MockRetryPendingConnectionsUseCase: RetryPendingConnectionsUseCaseProtocol {
    public var retryPendingConnections_calledTimes = 0
    
    public init() {}
    
    public func retryPendingConnections() {
        retryPendingConnections_calledTimes += 1
    }
}
