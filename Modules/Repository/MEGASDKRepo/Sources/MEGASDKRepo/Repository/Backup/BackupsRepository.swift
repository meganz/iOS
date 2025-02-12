import MEGADomain
import MEGASdk
import MEGASwift

public struct BackupsRepository: BackupsRepositoryProtocol {
    private let sdk: MEGASdk
    
    public static var newRepo: BackupsRepository {
        BackupsRepository(sdk: MEGASdk.sharedSdk)
    }
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func isBackupNode(_ node: NodeEntity) -> Bool {
        guard let megaNode = node.toMEGANode(in: sdk),
              let path = sdk.nodePath(for: megaNode),
              let backupRootNodePath = BackupRootNodeAccess.shared.nodePath else { return false }
        return path.hasPrefix(backupRootNodePath)
    }
    
    public func isBackupsRootNode(_ node: NodeEntity) -> Bool {
        guard let megaNode = node.toMEGANode(in: sdk),
              let path = sdk.nodePath(for: megaNode),
              let backupRootNodePath = BackupRootNodeAccess.shared.nodePath else { return false }
        return path == backupRootNodePath
    }
}
