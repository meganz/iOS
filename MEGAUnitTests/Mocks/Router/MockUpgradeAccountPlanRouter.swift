@testable import MEGA

final class MockUpgradeAccountPlanRouter: UpgradeAccountPlanRouting {
    private(set) var isFromAds: Bool
    private(set) var start_calledTimes = 0
    private(set) var showTermsAndPolicies_calledTimes = 0
    
    nonisolated init(isFromAds: Bool = false) {
        self.isFromAds = isFromAds
    }
    
    func showTermsAndPolicies() {
        showTermsAndPolicies_calledTimes += 1
    }
    
    func start() {
        start_calledTimes += 1
    }
}
