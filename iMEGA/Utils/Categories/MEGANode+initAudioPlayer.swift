import MEGAAppPresentation
import MEGAAudioPlayer

extension MEGANode {
    @MainActor
    private func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, messageId: NSNumber?, chatId: NSNumber?, isFromSharedItem: Bool, allNodes: [MEGANode]?) {
        
        // fixes [CC-5598] as we were passing in all nodes instead of just audio ones
        // this is the same check we do on a single node, when deciding if we can pass it to
        // audio player
        let allAudioNodes: [MEGANode]? = allNodes?.filter { node in
            node.name?.fileExtensionGroup.isMultiMedia == true &&
            node.name?.fileExtensionGroup.isVideo == false &&
            node.mnz_isPlayable()
        }
        
        AudioPlayerManager.shared.initFullScreenPlayer(
            node: node,
            fileLink: fileLink,
            filePaths: filePaths,
            isFolderLink: isFolderLink,
            presenter: presenter,
            messageId: messageId?.uint64Value ?? .invalid,
            chatId: chatId?.uint64Value ?? .invalid,
            isFromSharedItem: isFromSharedItem,
            allNodes: allAudioNodes
        )
    }
    
    @MainActor
    private func initMiniPlayer(node: MEGANode?, fileLink: String?, isFolderLink: Bool, presenter: UIViewController, isFromSharedItem: Bool) {
        AudioPlayerManager.shared.initMiniPlayer(
            node: node,
            fileLink: fileLink,
            filePaths: nil,
            isFolderLink: isFolderLink,
            presenter: presenter,
            shouldReloadPlayerInfo: true,
            shouldResetPlayer: true,
            isFromSharedItem: isFromSharedItem
        )
    }
    
    @MainActor
    @objc func presentAudioPlayer(node: MEGANode?, fileLink: String?, isFolderLink: Bool, presenter: UIViewController?, messageId: NSNumber?, chatId: NSNumber?, isFromSharedItem: Bool, allNodes: [MEGANode]?) {
        guard let presenter else {
            MEGALogError("[AudioPlayer] Unable to present player, presenter is nil")
            return
        }

        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .audioPlayerRevamp) {
            if let source = makeRevampedPlaybackSource(node: node,
                                                       fileLink: fileLink,
                                                       isFolderLink: isFolderLink,
                                                       chatId: chatId,
                                                       messageId: messageId,
                                                       allNodes: allNodes) {
                MEGAAudioPlayerViewRouter(
                    presenter: presenter,
                    actionsHandler: MEGAAudioPlayerActionsHandler.make(),
                    navigationFactory: MEGAAudioPlayerNavigationController.make()
                )
                .start(source: source)
            }
            return
        }

        let presenterSupportsMiniPlayer = (presenter as? (any AudioPlayerPresenterProtocol)) != nil
        let canShowMiniPlayer = presenterSupportsMiniPlayer && AudioPlayerManager.shared.isPlayerDefined() && AudioPlayerManager.shared.isPlayerAlive()
        
        if canShowMiniPlayer {
            initMiniPlayer(
                node: node,
                fileLink: fileLink,
                isFolderLink: isFolderLink,
                presenter: presenter,
                isFromSharedItem: isFromSharedItem
            )
        } else {
            initFullScreenPlayer(
                node: node,
                fileLink: fileLink,
                filePaths: nil,
                isFolderLink: isFolderLink,
                presenter: presenter,
                messageId: messageId,
                chatId: chatId,
                isFromSharedItem: isFromSharedItem,
                allNodes: allNodes
            )
        }
    }
    
    @MainActor
    private func makeRevampedPlaybackSource(node: MEGANode?,
                                            fileLink: String?,
                                            isFolderLink: Bool,
                                            chatId: NSNumber?,
                                            messageId: NSNumber?,
                                            allNodes: [MEGANode]?) -> PlaybackSource? {
        if isFolderLink, let node {
            let queue = (allNodes ?? []).map { $0.toNodeEntity() }
            return .folderLink(node: node.toNodeEntity(), queue: queue)
        }
        if let fileLink, let url = URL(string: fileLink) {
            return .fileLink(url: url)
        }
        if let node,
           let chatHandle = chatId?.uint64Value, chatHandle != .invalid,
           let messageHandle = messageId?.uint64Value, messageHandle != .invalid {
            return .chatMessage(node: node.toNodeEntity(),
                                chatId: chatHandle,
                                messageId: messageHandle)
        }
        if let node {
            let queue = (allNodes ?? []).map { $0.toNodeEntity() }
            return .cloudNode(node: node.toNodeEntity(), queue: queue)
        }
        return nil
    }

    @MainActor
    @objc func isAudioPlayerAliveAndPlayingCurrentNode() -> Bool {
        let manager = AudioPlayerManager.shared
        return manager.isPlayerAlive() && manager.isPlayingNode(self)
    }
}
