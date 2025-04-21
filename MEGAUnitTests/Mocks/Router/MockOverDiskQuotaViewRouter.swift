@testable import MEGA

final class MockOverDiskQuotaViewRouter: OverDiskQuotaViewRouting {
    private(set) var dismiss_calledTimes = 0
    private(set) var showUpgradePlanPage_calledTimes = 0
    private let dismissAction: () -> Void
    
    init(dismissAction: @escaping () -> Void = {}) {
        self.dismissAction = dismissAction
    }
    
    func dismiss() {
        dismiss_calledTimes += 1
        dismissAction()
    }
    
    func showUpgradePlanPage() {
        showUpgradePlanPage_calledTimes += 1
    }
}
