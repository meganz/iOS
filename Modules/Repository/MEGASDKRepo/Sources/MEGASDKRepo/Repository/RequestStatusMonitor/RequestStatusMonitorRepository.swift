import MEGADomain
import MEGASdk

public struct RequestStatusMonitorRepository: RequestStatusMonitorRepositoryProtocol {
    public static var newRepo: RequestStatusMonitorRepository {
        RequestStatusMonitorRepository(sdk: .sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func enableRequestStatusMonitor(_ enable: Bool) {
        sdk.enableRequestStatusMonitor(enable)
    }
    
    public func isRequestStatusMonitorEnabled() -> Bool {
        sdk.isRequestStatusMonitorEnabled
    }
}
