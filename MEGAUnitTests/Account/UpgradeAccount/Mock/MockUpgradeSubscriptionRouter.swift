@testable import MEGA

final class MockUpgradeSubscriptionRouter: UpgradeSubscriptionRouting {
    private(set) var upgradeCalled = 0
    
    nonisolated init() {}
    
    func showUpgradeAccount() {
        upgradeCalled += 1
    }
}
