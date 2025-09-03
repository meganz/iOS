@testable import MEGA

@MainActor
final class ForwardingAudioPlayerViewRouterMock: AudioPlayerViewRouting, @unchecked Sendable {
    private let handler: MockAudioPlayerHandler
    private(set) var showMiniPlayer_calledTimes = 0
    
    init(handler: MockAudioPlayerHandler) {
        self.handler = handler
    }
    
    func showMiniPlayer(node: MEGANode?, shouldReload: Bool) {
        showMiniPlayer_calledTimes += 1
        handler.initMiniPlayer(
            node: node,
            fileLink: nil,
            filePaths: nil,
            isFolderLink: false,
            presenter: UIViewController(),
            shouldReloadPlayerInfo: shouldReload,
            shouldResetPlayer: false,
            isFromSharedItem: false
        )
    }
    
    func showMiniPlayer(file: String, shouldReload: Bool) {
        showMiniPlayer_calledTimes += 1
        handler.initMiniPlayer(
            node: nil,
            fileLink: file,
            filePaths: nil,
            isFolderLink: false,
            presenter: UIViewController(),
            shouldReloadPlayerInfo: shouldReload,
            shouldResetPlayer: false,
            isFromSharedItem: false
        )
    }
    
    func dismiss(completion: @escaping () -> Void) {}
    func goToPlaylist(parentNodeName: String) {}
    func importNode(_ node: MEGANode) { }
    func share(sender: UIBarButtonItem?) {}
    func sendToChat() {}
    func showAction(for node: MEGANode, isFileLink: Bool, sender: Any) {}
    func showTermsOfServiceViolationAlert() {}
}
