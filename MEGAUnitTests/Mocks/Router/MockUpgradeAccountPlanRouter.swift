@testable import MEGA

final class MockUpgradeAccountPlanRouter: UpgradeAccountPlanRouting {
    var start_calledTimes = 0
    var showTermsAndPolicies_calledTimes = 0
    
    nonisolated init() {}
    
    func showTermsAndPolicies() {
        showTermsAndPolicies_calledTimes += 1
    }
    
    func start() {
        start_calledTimes += 1
    }
}
