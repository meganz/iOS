@testable import MEGA
final class MockUpgradeAccountRouter: UpgradeAccountRouting, @unchecked Sendable {
    var presentUpgradeTVCRecorder = FuncCallRecorder<Void, Void>()
    func presentUpgradeTVC() {
        presentUpgradeTVCRecorder.call(())
    }
}
