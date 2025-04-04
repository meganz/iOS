@testable import MEGA

final class MockAudioPlaylistViewRouter: AudioPlaylistViewRouting, @unchecked Sendable {
    var dismiss_calledTimes = 0
    var navigateToDetail_calledTimes = 0
    var start_calledTimes = 0
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func navigateToDetail(node: MEGANode) {
        navigateToDetail_calledTimes += 1
    }
    
    func start() {
        start_calledTimes += 1
    }
}
