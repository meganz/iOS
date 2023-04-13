public protocol MyBackupsUseCaseProtocol {
    func hasBackupNode(in nodes: [NodeEntity]) async -> Bool
    func isBackupNode(_ node: NodeEntity) -> Bool
    func isMyBackupsRootNode(_ node: NodeEntity) -> Bool
    func isBackupNodeHandle(_ nodeHandle: HandleEntity) -> Bool
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool
    func isMyBackupsRootNodeEmpty() async -> Bool
    func myBackupsRootNodeSize() async -> UInt64
    func myBackupsRootNode() async throws -> NodeEntity
}

public struct MyBackupsUseCase<T: MyBackupsRepositoryProtocol, U: NodeRepositoryProtocol>: MyBackupsUseCaseProtocol {
    private let myBackupsRepository: T
    private let nodeRepository: U
    
    public init(myBackupsRepository: T, nodeRepository: U) {
        self.myBackupsRepository = myBackupsRepository
        self.nodeRepository = nodeRepository
    }
    
    public func hasBackupNode(in nodes: [NodeEntity]) -> Bool {
        nodes.contains {
            myBackupsRepository.isBackupNode($0)
        }
    }
    
    public func isBackupNode(_ node: NodeEntity) -> Bool {
        myBackupsRepository.isBackupNode(node)
    }
    
    public func isMyBackupsRootNode(_ node: NodeEntity) -> Bool {
        myBackupsRepository.isMyBackupsRootNode(node)
    }
    
    public func isBackupNodeHandle(_ nodeHandle: HandleEntity) -> Bool {
        guard let node = nodeRepository.nodeForHandle(nodeHandle) else { return false }
        return isBackupNode(node)
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        myBackupsRepository.isBackupDeviceFolder(node)
    }
    
    public func isMyBackupsRootNodeEmpty() async -> Bool {
        await myBackupsRepository.isBackupRootNodeEmpty()
    }
    
    public func myBackupsRootNodeSize() async -> UInt64 {
        do {
            return try await myBackupsRepository.backupRootNodeSize()
        } catch {
            return 0
        }
    }
    
    public func myBackupsRootNode() async throws -> NodeEntity {
        try await myBackupsRepository.myBackupRootNode()
    }
}
