public protocol MyBackupsUseCaseProtocol {
    func containsABackupNode(_ nodes: [NodeEntity]) async -> Bool
    func isBackupNode(_ node: NodeEntity) async -> Bool
    func isBackupNodeHandle(_ nodeHandle: HandleEntity) async -> Bool
    func isMyBackupsNodeChild(_ node: NodeEntity) async -> Bool
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool
    func isMyBackupsRootNodeEmpty() async -> Bool
    func isMyBackupsRootNode(_ node: NodeEntity) async -> Bool
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
    
    public func containsABackupNode(_ nodes: [NodeEntity]) async -> Bool {
        await withTaskGroup(of: Bool.self) { group -> Bool in
            nodes.forEach { node in
                group.addTask {
                    await isBackupNode(node)
                }
            }
            
            return await group.contains(true)
        }
    }
    
    public func isBackupNode(_ node: NodeEntity) async -> Bool {
        return await withTaskGroup(of: Bool.self) { group -> Bool in
            group.addTask {
                return await isMyBackupsRootNode(node)
            }
            
            group.addTask {
                return await isMyBackupsNodeChild(node)
            }
            
            return await group.contains(true)
        }
    }
    
    public func isBackupNodeHandle(_ nodeHandle: HandleEntity) async -> Bool {
        guard let node = nodeRepository.nodeForHandle(nodeHandle) else { return false }
        return await isBackupNode(node)
    }
    
    public func isMyBackupsNodeChild(_ node: NodeEntity) async -> Bool {
        do {
            let myBackupsNode = try await myBackupsRootNode()
            return nodeRepository.isNode(node, descendantOf: myBackupsNode)
        } catch {
            return false
        }
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        myBackupsRepository.isBackupDeviceFolder(node)
    }
    
    public func isMyBackupsRootNodeEmpty() async -> Bool {
        await myBackupsRepository.isBackupRootNodeEmpty()
    }
    
    public func isMyBackupsRootNode(_ node: NodeEntity) async -> Bool {
        do {
            let myBackupsNode = try await myBackupsRootNode()
            return myBackupsNode == node
        } catch {
            return false
        }
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
