import MEGADomain
import MEGASdk

public struct RetryPendingConnectionsRepository: RetryPendingConnectionsRepositoryProtocol {
    public static var newRepo: RetryPendingConnectionsRepository {
        RetryPendingConnectionsRepository(sdk: .sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func retryPendingConnections() {
        sdk.retryPendingConnections()
    }
}
