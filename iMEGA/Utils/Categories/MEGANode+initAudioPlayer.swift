import MEGAAppPresentation
import MEGAAppSDKRepo
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
    @objc func presentAudioPlayer(node: MEGANode?, fileLink: String?, isFolderLink: Bool, presenter: UIViewController?, messageId: NSNumber?, chatId: NSNumber?, isFromSharedItem: Bool, allNodes: [MEGANode]?, sourcePage: NodeSourcePage = .unknown) {
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
                                                       allNodes: allNodes,
                                                       sourcePage: sourcePage) {
                MEGAAudioPlayerViewRouter(
                    presenter: presenter,
                    actionsHandler: MEGAAudioPlayerActionsHandler.make()
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
                                            allNodes: [MEGANode]?,
                                            sourcePage: NodeSourcePage) -> PlaybackSource? {
        if isFolderLink, let node {
            // Folder link nodes belong to the folder link SDK instance, so the account SDK cannot resolve
            // their handles. Authorizing here attaches the node key and lets the authorized objects travel
            // with the queue, which is what makes the three-dot actions downstream work (IOS-12360).
            let folderLinkSdk = MEGASdk.sharedFolderLinkSdk
            let queue = (allNodes ?? []).map { folderLinkSdk.authorizeNode($0) ?? $0 }
            return .folderLink(node: folderLinkSdk.authorizeNode(node) ?? node, queue: queue)
        }
        if let fileLink, let url = URL(string: fileLink) {
            guard let node else {
                assertionFailure("[AudioPlayer] .fileLink source has nil node — resolve node before presenting player")
                MEGALogError("[AudioPlayer] .fileLink source has nil node — playback skipped")
                return nil
            }
            return .fileLink(url: url, node: node)
        }
        if let node,
           let chatHandle = chatId?.uint64Value, chatHandle != .invalid,
           let messageHandle = messageId?.uint64Value, messageHandle != .invalid {
            return .chatMessage(node: node.toNodeEntity())
        }
        if let node {
            let queue = (allNodes ?? []).map { $0.toNodeEntity() }
            switch sourcePage {
            case .recents:
                return .recents(node: node.toNodeEntity(), queue: queue)
            case .allAudios:
                return .allAudios(node: node.toNodeEntity(), queue: queue)
            case .search:
                return .searchResult(node: node.toNodeEntity())
            default:
                return .cloudNode(node: node.toNodeEntity(), queue: queue)
            }
        }
        return nil
    }

    @MainActor
    @objc func isAudioPlayerAliveAndPlayingCurrentNode() -> Bool {
        let manager = AudioPlayerManager.shared
        return manager.isPlayerAlive() && manager.isPlayingNode(self)
    }
}
