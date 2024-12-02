@testable import MEGA

final class MockOverDiskQuotaViewRouter: OverDiskQuotaViewRouting {
    private(set) var dismiss_calledTimes = 0
    private(set) var showUpgradePlanPage_calledTimes = 0
    private(set) var navigateToCloudDriveTab_calledTimes = 0
    
    init() {}
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func showUpgradePlanPage() {
        showUpgradePlanPage_calledTimes += 1
    }
    
    func navigateToCloudDriveTab() {
        navigateToCloudDriveTab_calledTimes += 1
    }
}
