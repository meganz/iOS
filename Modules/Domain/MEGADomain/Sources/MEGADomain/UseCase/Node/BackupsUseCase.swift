public protocol BackupsUseCaseProtocol {
    func hasBackupNode(in nodes: [NodeEntity]) async -> Bool
    func isBackupNode(_ node: NodeEntity) -> Bool
    func isBackupsRootNode(_ node: NodeEntity) -> Bool
    func isBackupNodeHandle(_ nodeHandle: HandleEntity) -> Bool
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool
    func isBackupsRootNodeEmpty() async -> Bool
    func backupsRootNodeSize() async -> UInt64
    func backupsRootNode() async throws -> NodeEntity
}

public struct BackupsUseCase<T: BackupsRepositoryProtocol, U: NodeRepositoryProtocol>: BackupsUseCaseProtocol {
    private let backupsRepository: T
    private let nodeRepository: U
    
    public init(backupsRepository: T, nodeRepository: U) {
        self.backupsRepository = backupsRepository
        self.nodeRepository = nodeRepository
    }
    
    public func hasBackupNode(in nodes: [NodeEntity]) -> Bool {
        nodes.contains {
            backupsRepository.isBackupNode($0)
        }
    }
    
    public func isBackupNode(_ node: NodeEntity) -> Bool {
        backupsRepository.isBackupNode(node)
    }
    
    public func isBackupsRootNode(_ node: NodeEntity) -> Bool {
        backupsRepository.isBackupsRootNode(node)
    }
    
    public func isBackupNodeHandle(_ nodeHandle: HandleEntity) -> Bool {
        guard let node = nodeRepository.nodeForHandle(nodeHandle) else { return false }
        return isBackupNode(node)
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        backupsRepository.isBackupDeviceFolder(node)
    }
    
    public func isBackupsRootNodeEmpty() async -> Bool {
        await backupsRepository.isBackupRootNodeEmpty()
    }
    
    public func backupsRootNodeSize() async -> UInt64 {
        do {
            return try await backupsRepository.backupRootNodeSize()
        } catch {
            return 0
        }
    }
    
    public func backupsRootNode() async throws -> NodeEntity {
        try await backupsRepository.backupRootNode()
    }
}
