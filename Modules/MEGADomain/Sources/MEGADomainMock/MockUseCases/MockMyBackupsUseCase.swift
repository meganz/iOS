import MEGADomain
import Foundation

public struct MockMyBackupsUseCase: MyBackupsUseCaseProtocol {
    private let isMyBackupsNode: Bool
    private var containsAnyBackupsNode: Bool
    private var isMyBackupsRootNodeChild: Bool
    private var isMyBackupsRootNode: Bool
    private var nodeSize: UInt64
    private var isMyBackupsDeviceFolder: Bool
    private var isMyBackupsRootNodeEmpty: Bool
    private var isInMyBackups: Bool
    
    public init(isMyBackupsNode: Bool = false, containsAnyBackupsNode: Bool = false, isMyBackupsRootNodeChild: Bool = false, isMyBackupsRootNode: Bool = false, nodeSize: UInt64 = 0, isMyBackupsDeviceFolder: Bool = false, isMyBackupsRootNodeEmpty: Bool = false, isInMyBackups: Bool = false) {
        self.isMyBackupsNode = isMyBackupsNode
        self.containsAnyBackupsNode = containsAnyBackupsNode
        self.isMyBackupsRootNodeChild = isMyBackupsRootNodeChild
        self.isMyBackupsRootNode = isMyBackupsRootNode
        self.nodeSize = nodeSize
        self.isMyBackupsDeviceFolder = isMyBackupsDeviceFolder
        self.isMyBackupsRootNodeEmpty = isMyBackupsRootNodeEmpty
        self.isInMyBackups = isInMyBackups
    }
    
    public func containsABackupNode(_ nodes: [MEGADomain.NodeEntity]) async -> Bool {
        containsAnyBackupsNode
    }
    
    public func isBackupNode(_ node: MEGADomain.NodeEntity) async -> Bool {
        isMyBackupsNode
    }
    
    public func isMyBackupsNodeChild(_ node: MEGADomain.NodeEntity) async -> Bool {
        isMyBackupsRootNodeChild
    }
    
    public func isBackupDeviceFolder(_ node: MEGADomain.NodeEntity) -> Bool {
        isMyBackupsDeviceFolder
    }
    
    public func isMyBackupsRootNodeEmpty() async -> Bool {
        isMyBackupsRootNodeEmpty
    }
    
    public func isMyBackupsRootNode(_ node: MEGADomain.NodeEntity) async -> Bool {
        isMyBackupsRootNode
    }
    
    public func myBackupsRootNodeSize() async -> UInt64 {
        nodeSize
    }
    
    public func myBackupsRootNode() async throws -> MEGADomain.NodeEntity {
        NodeEntity(name: "myBackups", handle: 1)
    }
}
