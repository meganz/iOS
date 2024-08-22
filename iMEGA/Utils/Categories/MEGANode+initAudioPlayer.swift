extension MEGANode {
    @MainActor
    @objc func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, messageId: NSNumber?, chatId: NSNumber?, isFromSharedItem: Bool, allNodes: [MEGANode]?) {
        
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
}
