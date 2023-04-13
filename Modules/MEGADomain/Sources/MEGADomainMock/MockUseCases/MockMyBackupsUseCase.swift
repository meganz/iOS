import MEGADomain
import Foundation

public struct MockMyBackupsUseCase: MyBackupsUseCaseProtocol {
    private let isMyBackupsNode: Bool
    private var containsABackupNode: Bool
    private var isMyBackupsRootNode: Bool
    private var nodeSize: UInt64
    private var isMyBackupsDeviceFolder: Bool
    private var isMyBackupsRootNodeEmpty: Bool
    private var isInMyBackups: Bool
    
    public init(isMyBackupsNode: Bool = false, isMyBackupsRootNode: Bool = false, containsABackupNode: Bool = false, nodeSize: UInt64 = 0, isMyBackupsDeviceFolder: Bool = false, isMyBackupsRootNodeEmpty: Bool = false, isInMyBackups: Bool = false) {
        self.isMyBackupsNode = isMyBackupsNode
        self.isMyBackupsRootNode = isMyBackupsRootNode
        self.containsABackupNode = containsABackupNode
        self.isMyBackupsRootNode = isMyBackupsRootNode
        self.nodeSize = nodeSize
        self.isMyBackupsDeviceFolder = isMyBackupsDeviceFolder
        self.isMyBackupsRootNodeEmpty = isMyBackupsRootNodeEmpty
        self.isInMyBackups = isInMyBackups
    }
    
    public func hasBackupNode(in nodes: [NodeEntity]) -> Bool {
        containsABackupNode
    }
    
    public func isBackupNode(_ node: NodeEntity) -> Bool {
        isMyBackupsNode
    }
    
    public func isMyBackupsRootNode(_ node: NodeEntity) -> Bool {
        isMyBackupsRootNode
    }
    
    public func isBackupNodeHandle(_ nodeHandle: HandleEntity) -> Bool {
        isMyBackupsNode
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        isMyBackupsDeviceFolder
    }
    
    public func isMyBackupsRootNodeEmpty() async -> Bool {
        isMyBackupsRootNodeEmpty
    }
    
    public func isMyBackupsRootNode(_ node: NodeEntity) async -> Bool {
        isMyBackupsRootNode
    }
    
    public func myBackupsRootNodeSize() async -> UInt64 {
        nodeSize
    }
    
    public func myBackupsRootNode() async throws -> NodeEntity {
        NodeEntity(name: "myBackups", handle: 1)
    }
}
