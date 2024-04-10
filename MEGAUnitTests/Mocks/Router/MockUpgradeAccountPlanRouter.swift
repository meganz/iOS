@testable import MEGA

final class MockUpgradeAccountPlanRouter: UpgradeAccountPlanRouting {
    var showTermsAndPolicies_calledTimes = 0
    
    func showTermsAndPolicies() {
        showTermsAndPolicies_calledTimes += 1
    }
}
