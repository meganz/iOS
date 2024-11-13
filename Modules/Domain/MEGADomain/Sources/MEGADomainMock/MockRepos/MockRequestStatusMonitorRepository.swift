import MEGADomain

public final class MockRequestStatusMonitorRepository: RequestStatusMonitorRepositoryProtocol {
    public static var newRepo: MockRequestStatusMonitorRepository {
        MockRequestStatusMonitorRepository()
    }
    
    private var isEnabled: Bool = false
    
    public func enableRequestStatusMonitor(_ enable: Bool) {
        isEnabled = enable
    }
    
    public func isRequestStatusMonitorEnabled() -> Bool {
        isEnabled
    }
}
