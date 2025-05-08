@testable import MEGA

final class MockAudioPlayerViewRouter: AudioPlayerViewRouting {
    var dismiss_calledTimes = 0
    var goToPlaylist_calledTimes = 0
    var showNodesMiniPlayer_calledTimes = 0
    var showMiniPlayer_calledTimes = 0
    var importNode_calledTimes = 0
    var share_calledTimes = 0
    var sendToContact_calledTimes = 0
    var showAction_calledTimes = 0
    
    func dismiss(completion: @escaping () -> Void) {
        dismiss_calledTimes += 1
    }
    
    func goToPlaylist(parentNodeName: String) {
        goToPlaylist_calledTimes += 1
    }
    
    func showMiniPlayer(node: MEGANode?, shouldReload: Bool) {
        showNodesMiniPlayer_calledTimes += 1
    }
    
    func showMiniPlayer(file: String, shouldReload: Bool) {
        showMiniPlayer_calledTimes += 1
    }
    
    func importNode(_ node: MEGANode) {
        importNode_calledTimes += 1
    }
    
    func share(sender: UIBarButtonItem?) {
        share_calledTimes += 1
    }
    
    func sendToChat() {
        sendToContact_calledTimes += 1
    }
    
    func showAction(for node: MEGANode, sender: Any) {
        showAction_calledTimes += 1
    }
}
