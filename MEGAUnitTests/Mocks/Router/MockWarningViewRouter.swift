@testable import MEGA

final class MockWarningViewRouter: WarningBannerViewRouting {
    var goToSettings_calledTimes = 0
    var presentUpgradeScreen_calledTimes = 0
    
    nonisolated init() {}
    
    func goToSettings() {
        goToSettings_calledTimes += 1
    }
    
    func presentUpgradeScreen() {
        presentUpgradeScreen_calledTimes += 1
    }
}
