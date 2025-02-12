public protocol BackupsUseCaseProtocol: Sendable {
    func hasBackupNode(in nodes: [NodeEntity]) async -> Bool
    func isBackupNode(_ node: NodeEntity) -> Bool
    func isBackupsRootNode(_ node: NodeEntity) -> Bool
    func isBackupNodeHandle(_ nodeHandle: HandleEntity) -> Bool
    func parentsForBackupHandle(_ handle: HandleEntity) async -> [NodeEntity]?
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
    
    public func parentsForBackupHandle(_ handle: HandleEntity) async -> [NodeEntity]? {
        guard let node = nodeRepository.nodeForHandle(handle) else { return nil }
        return await nodeRepository.parents(of: node).filter {
            $0.parentHandle != .invalid
        }
    }
}
