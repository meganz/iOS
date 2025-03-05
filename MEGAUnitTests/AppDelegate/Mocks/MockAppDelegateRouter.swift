@testable import MEGA

final class MockAppDelegateRouter: AppDelegateRouting {
    private(set) var showOverDiskQuotaCalled = 0
    
    nonisolated init() {}
    
    func showOverDiskQuota() {
        showOverDiskQuotaCalled += 1
    }
}
