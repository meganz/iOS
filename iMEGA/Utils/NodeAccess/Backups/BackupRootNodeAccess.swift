import Foundation

final class BackupRootNodeAccess: NodeAccess {
    @objc static let shared = BackupRootNodeAccess(configuration:
                                                            NodeAccessConfiguration(updateInMemoryNotificationName: .MEGABackupRootFolderUpdatedInMemory,
                                                                                    updateInRemoteNotificationName: .MEGABackupRootFolderUpdatedInRemote,
                                                                                    loadNodeRequest: MEGASdkManager.sharedMEGASdk().getMyBackupsFolder))
    
    override init(configuration: NodeAccessConfiguration) {
        super.init(configuration: configuration)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveNodesCurrentNotification), name: .MEGANodesCurrent, object: nil)
    }
         
    @objc func didReceiveNodesCurrentNotification() {
        BackupRootNodeAccess.shared.loadNode()
    }
}
