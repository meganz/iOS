@testable import MEGA
final class MockUpgradeAccountRouter: UpgradeAccountRouting {
    var presentUpgradeTVCRecorder = FuncCallRecorder<Void, Void>()
    func presentUpgradeTVC() {
        presentUpgradeTVCRecorder.call(())
    }
}
