import MEGADomain
import Foundation

public struct MockInboxRepository: InboxRepositoryProtocol {
    public static let newRepo = MockInboxRepository()
    
    private let currentBackupNode: NodeEntity?
    private let isBackupRootNodeEmpty: Bool
    private let currentInboxNode: NodeEntity?
    
    public init(currentBackupNode: NodeEntity? = nil, isBackupRootNodeEmpty: Bool = false, currentInboxNode: NodeEntity? = nil) {
        self.currentBackupNode = currentBackupNode
        self.isBackupRootNodeEmpty = isBackupRootNodeEmpty
        self.currentInboxNode = currentInboxNode
    }
    
    public func containsInboxRootNode(_ array: [NodeEntity]) -> Bool {
        array.contains(where: isInboxRootNode)
    }
    
    public func isInboxRootNode(_ node: NodeEntity) -> Bool {
        node == currentInboxNode
    }
    
    public func backupRootNodeSize() async throws -> UInt64 {
        UInt64(currentBackupNode?.size ?? 0)
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        guard node.deviceId != nil else { return false }
        return currentBackupNode?.handle == node.parentHandle
    }
    
    public func isBackupRootNodeEmpty() async -> Bool {
        isBackupRootNodeEmpty
    }
    
    public func inboxNode() -> NodeEntity? {
        currentInboxNode
    }
}
