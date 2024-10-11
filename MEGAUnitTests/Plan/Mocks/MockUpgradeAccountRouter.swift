@testable import MEGA
final class MockUpgradeAccountRouter: UpgradeAccountRouting, @unchecked Sendable {
    var presentUpgradeTVCRecorder = FuncCallRecorder<Void, Void>()
    
    nonisolated init() {}
    
    func presentUpgradeTVC() {
        presentUpgradeTVCRecorder.call(())
    }
}
