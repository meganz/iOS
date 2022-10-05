public protocol InboxUseCaseProtocol {
    func isInboxNode(_ node: NodeEntity) -> Bool
    func containsAnyInboxNode(_ nodes: [NodeEntity]) -> Bool
    func isInboxRootNode(_ node: NodeEntity) -> Bool
    func isInInbox(_ node: NodeEntity) -> Bool
    func backupRootNodeSize() async throws -> UInt64
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool
    func isBackupRootNodeEmpty() async -> Bool
    func myBackupRootNode() async throws -> NodeEntity
}

public struct InboxUseCase<T: InboxRepositoryProtocol, U: NodeRepositoryProtocol>: InboxUseCaseProtocol {
    
    private let inboxRepository: T
    private let nodeRepository: U
    
    public init(inboxRepository: T, nodeRepository: U) {
        self.inboxRepository = inboxRepository
        self.nodeRepository = nodeRepository
    }
    
    public func isInboxNode(_ node: NodeEntity) -> Bool {
        isInboxRootNode(node) || isInInbox(node)
    }
    
    public func containsAnyInboxNode(_ nodes: [NodeEntity]) -> Bool {
        inboxRepository.containsInboxRootNode(nodes) || nodes.contains(where: isInInbox)
    }
    
    public func isInboxRootNode(_ node: NodeEntity) -> Bool {
        inboxRepository.isInboxRootNode(node)
    }
    
    public func isInInbox(_ node: NodeEntity) -> Bool {
        guard let inboxFolderNode = inboxRepository.inboxNode() else {
            return false
        }
        
        return nodeRepository.isNode(node, descendantOf: inboxFolderNode)
    }
    
    public func backupRootNodeSize() async throws -> UInt64 {
        try await inboxRepository.backupRootNodeSize()
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        inboxRepository.isBackupDeviceFolder(node)
    }
    
    public func isBackupRootNodeEmpty() async -> Bool {
        await inboxRepository.isBackupRootNodeEmpty()
    }
    
    public func myBackupRootNode() async throws -> NodeEntity {
        try await inboxRepository.myBackupRootNode()
    }
}
