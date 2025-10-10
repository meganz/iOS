import MEGAAppPresentation

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
    @objc func isAudioPlayerAliveAndPlayingCurrentNode() -> Bool {
        let manager = AudioPlayerManager.shared
        return manager.isPlayerAlive() && manager.isPlayingNode(self)
    }
}
