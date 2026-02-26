import FolderLink

struct FolderLinkLogoutPolicy: FolderLinkLogoutPolicyProtocol {
    func shouldLogoutUponFolderLinkDismiss() -> Bool {
        if AudioPlayerManager.shared.hasAlivePlayerThatStartedFromFolderLink() {
            false
        } else {
            true
        }
    }
}
