extension MEGANode {
    @objc func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, messageId: NSNumber?, chatId: NSNumber?) {
        AudioPlayerManager.shared.initFullScreenPlayer(
            node: node,
            fileLink: fileLink,
            filePaths: filePaths,
            isFolderLink: isFolderLink,
            presenter: presenter,
            messageId: messageId?.uint64Value ?? .invalid,
            chatId: chatId?.uint64Value ?? .invalid
        )
    }
}
