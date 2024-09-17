import Foundation
import MEGASdk

final public class BackupRootNodeAccess: NodeAccess, @unchecked Sendable {
    @objc public static let shared = BackupRootNodeAccess(
        configuration:
            NodeAccessConfiguration(
                updateInMemoryNotificationName: .MEGABackupRootFolderUpdatedInMemory,
                updateInRemoteNotificationName: .MEGABackupRootFolderUpdatedInRemote,
                loadNodeRequest: BackupRootNodeAccess.loadRootNode
            )
    )
    
    public override init(configuration: NodeAccessConfiguration) {
        super.init(configuration: configuration)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveNodesCurrentNotification), name: .MEGANodesCurrent, object: nil)
    }
    
    @objc func didReceiveNodesCurrentNotification() {
        BackupRootNodeAccess.shared.loadNode()
    }
    
    private static func loadRootNode(delegate: any MEGARequestDelegate) {
        MEGASdk.sharedSdk.getUserAttributeType(.backupsFolder, delegate: delegate)
    }
}
