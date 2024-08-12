public protocol ShareUseCaseProtocol: Sendable {
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity]
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity]
    func areCredentialsVerifed(of user: UserEntity) -> Bool
    func user(from node: NodeEntity) -> UserEntity?
    func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity]
    
    ///  Determines if the given sequence of Node Entities contains any sensitive elements or there descending children nodes are sensitive.
    /// - Parameter nodes: Sequence of NodeEntities to iterate over and determine if are sensitive or if its descendant nodes are sensitive
    /// - Returns: True, if any node contains descendant sensitive nodes, else false.
    func containsSensitiveContent(in nodes: some Sequence<NodeEntity>) async throws -> Bool
}

public struct ShareUseCase<T: ShareRepositoryProtocol, S: FilesSearchRepositoryProtocol, N: NodeRepositoryProtocol>: ShareUseCaseProtocol {
    private let shareRepository: T
    private let filesSearchRepository: S
    private let nodeRepository: N

    public init(shareRepository: T,
                filesSearchRepository: S,
                nodeRepository: N) {
        self.shareRepository = shareRepository
        self.filesSearchRepository = filesSearchRepository
        self.nodeRepository = nodeRepository
    }
    
    public func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        shareRepository.allPublicLinks(sortBy: order)
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        shareRepository.allOutShares(sortBy: order)
    }

    public func areCredentialsVerifed(of user: UserEntity) -> Bool {
        shareRepository.areCredentialsVerifed(of: user)
    }

    public func user(from node: NodeEntity) -> UserEntity? {
        shareRepository.user(sharing: node)
    }
    
    public func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity] {
        try await withThrowingTaskGroup(of: HandleEntity.self, returning: [HandleEntity].self) { group in
            nodes.forEach { node in
                group.addTask {
                    return try await shareRepository.createShareKey(forNode: node)
                }
            }
            
            return try await group.reduce(into: [HandleEntity](), { result, handle in
                result.append(handle)
            })
        }
    }
    
    public func containsSensitiveContent(in nodes: some Sequence<NodeEntity>) async throws -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { taskGroup in
            defer { taskGroup.cancelAll() }
            
            taskGroup.addTasksUnlessCancelled(for: nodes) { node in
                if try await isSensitive(node: node) {
                    true
                } else if node.isFile {
                    false
                } else {
                    try await containSensitiveDescendants(in: node)
                }
            }
            
            return try await taskGroup.contains(true)
        }
    }
    
    private func isSensitive(node: NodeEntity) async throws -> Bool {
        if node.isMarkedSensitive {
            true
        } else {
            try await nodeRepository.isInheritingSensitivity(node: node)
        }
    }
    
    private func containSensitiveDescendants(in node: NodeEntity) async throws -> Bool {
        try await filesSearchRepository.search(filter: .recursive(
            searchTargetLocation: .parentNode(node),
            supportCancel: false,
            sortOrderType: .defaultAsc,
            formatType: .unknown,
            sensitiveFilterOption: .sensitiveOnly)).isNotEmpty
    }
}
