@testable import MEGA

final class MockMiniPlayerViewRouter: MiniPlayerViewRouting {
    var dismiss_calledTimes = 0
    var showPlayer_calledTimes = 0
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func showPlayer(node: MEGANode?, filePath: String?) {
        showPlayer_calledTimes += 1
    }
}
