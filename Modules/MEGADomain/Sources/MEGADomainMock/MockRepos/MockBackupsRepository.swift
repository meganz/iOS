import MEGADomain
import Foundation

public struct MockBackupsRepository: BackupsRepositoryProtocol {
    public static let newRepo = MockBackupsRepository()
    private let currentBackupNode: NodeEntity
    private let isBackupRootNodeEmpty: Bool
    private let isBackupNode: Bool
    
    public init(currentBackupNode: NodeEntity = NodeEntity(name: "backup"), isBackupRootNodeEmpty: Bool = false, isBackupNode: Bool = false) {
        self.currentBackupNode = currentBackupNode
        self.isBackupRootNodeEmpty = isBackupRootNodeEmpty
        self.isBackupNode = isBackupNode
    }
    
    public func isBackupRootNodeEmpty() async -> Bool {
        isBackupRootNodeEmpty
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        guard node.deviceId != nil else { return false }
        return currentBackupNode.handle == node.parentHandle
    }
    
    public func backupRootNodeSize() async throws -> UInt64 {
        UInt64(currentBackupNode.size)
    }
    
    public func myBackupRootNode() async throws -> NodeEntity {
        currentBackupNode
    }
    
    public func isBackupNode(_ node: NodeEntity) -> Bool {
        isBackupNode
    }
    
    public func isBackupsRootNode(_ node: NodeEntity) -> Bool {
        currentBackupNode.handle == node.handle
    }
}
