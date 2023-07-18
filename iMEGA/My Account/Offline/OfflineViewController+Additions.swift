extension OfflineViewController {
    
    @objc
    func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController) {
        AudioPlayerManager.shared.initFullScreenPlayer(
            node: node,
            fileLink: fileLink,
            filePaths: filePaths,
            isFolderLink: isFolderLink,
            presenter: presenter,
            messageId: .invalid,
            chatId: .invalid
        )
    }
    
    @objc
    func configureNavigationBar() {
        let title = screenTitle
        setMenuCapableBackButtonWith(menuTitle: title)
        navigationItem.title = title
    }
    
    private var screenTitle: String {
        if let path = folderPathFromOffline?.lastPathComponent {
            return path
        } else {
            return Strings.Localizable.offline
        }
    }
}
