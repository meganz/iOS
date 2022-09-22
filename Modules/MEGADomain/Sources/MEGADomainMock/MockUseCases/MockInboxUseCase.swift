import MEGADomain
import Foundation

public struct MockInboxUseCase: InboxUseCaseProtocol {
    var isInboxNode: Bool
    var containsAnyInboxNode: Bool
    var isInboxRootNode: Bool
    var nodeSize: UInt64
    var isBackupDeviceFolder: Bool
    var isBackupRootFolderEmpty: Bool
    var isInInbox: Bool
    
    public init(isInboxNode: Bool = false, containsAnyInboxNode: Bool = false, isInboxRootNode: Bool = false, nodeSize: UInt64 = 0, isBackupDeviceFolder: Bool = false, isBackupRootFolderEmpty: Bool = false, isInInbox: Bool = false) {
        self.isInboxNode = isInboxNode
        self.containsAnyInboxNode = containsAnyInboxNode
        self.isInboxRootNode = isInboxRootNode
        self.nodeSize = nodeSize
        self.isBackupDeviceFolder = isBackupDeviceFolder
        self.isBackupRootFolderEmpty = isBackupRootFolderEmpty
        self.isInInbox = isInInbox
    }
    
    public func isInboxNode(_ node: NodeEntity) -> Bool {
        isInboxNode
    }
    
    public func containsAnyInboxNode(_ nodes: [NodeEntity]) -> Bool {
        containsAnyInboxNode
    }
    
    public func isInboxRootNode(_ node: NodeEntity) -> Bool {
        isInboxRootNode
    }
    
    public func backupRootNodeSize() async throws -> UInt64 {
        nodeSize
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        isBackupDeviceFolder
    }
    
    public func isBackupRootNodeEmpty() async -> Bool {
        isBackupRootFolderEmpty
    }
    
    public func isInInbox(_ node: NodeEntity) -> Bool {
        isInInbox
    }
}
