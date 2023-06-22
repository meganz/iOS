import Foundation
import MEGADomain

public struct MockBackupsUseCase: BackupsUseCaseProtocol {
    private let isBackupsNode: Bool
    private var containsABackupNode: Bool
    private var isBackupsRootNode: Bool
    private var nodeSize: UInt64
    private var isBackupsDeviceFolder: Bool
    private var isBackupsRootNodeEmpty: Bool
    private var isInBackups: Bool
    
    public init(isBackupsNode: Bool = false, isBackupsRootNode: Bool = false, containsABackupNode: Bool = false, nodeSize: UInt64 = 0, isBackupsDeviceFolder: Bool = false, isBackupsRootNodeEmpty: Bool = false, isInBackups: Bool = false) {
        self.isBackupsNode = isBackupsNode
        self.isBackupsRootNode = isBackupsRootNode
        self.containsABackupNode = containsABackupNode
        self.nodeSize = nodeSize
        self.isBackupsDeviceFolder = isBackupsDeviceFolder
        self.isBackupsRootNodeEmpty = isBackupsRootNodeEmpty
        self.isInBackups = isInBackups
    }
    
    public func hasBackupNode(in nodes: [NodeEntity]) -> Bool {
        containsABackupNode
    }
    
    public func isBackupNode(_ node: NodeEntity) -> Bool {
        isBackupsNode
    }
    
    public func isBackupsRootNode(_ node: NodeEntity) -> Bool {
        isBackupsRootNode
    }
    
    public func isBackupNodeHandle(_ nodeHandle: HandleEntity) -> Bool {
        isBackupsNode
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        isBackupsDeviceFolder
    }
    
    public func isBackupsRootNodeEmpty() async -> Bool {
        isBackupsRootNodeEmpty
    }
    
    public func backupsRootNodeSize() async -> UInt64 {
        nodeSize
    }
    
    public func backupsRootNode() async throws -> NodeEntity {
        NodeEntity(name: "Backups", handle: 1)
    }
}
